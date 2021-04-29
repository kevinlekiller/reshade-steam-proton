#!/bin/bash
<<LICENSE
    Copyright (C) 2021  kevinlekiller
    
    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
    https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html
LICENSE
<<DESCRIPTION
    Bash script to download ReShade and the shaders and link them to Steam games on Linux.
    By linking, we can re-run this script and all the games automatically get the newest ReShade and
    shader versions.
    
    We can use this script to globally update ReShade and the shaders for all games (press Control+C when you get
    to the part that asks you for the steamid), we can also use it to install ReShade for a specific game, this
    will also make sure ReShade and the shaders are up to date.
    
    Requires grep, curl, 7z, wget, protontricks.
    
    Tested on various DX9 / DX11 games, doesn't load on some games that use a launcher (Final Fantasy X/X-2 HD Remaster for example).
    
    Example usage:
    
    If we want to install ReShade on Back To The Future Episode 1:
    
    First we run the game, so steam can create the various required directories. Exit the game.
    
    Run this command to find the steamid: protontricks -s Back To The Future
    We then get the name / steamid: Back to the Future: Ep 1 - It's About Time (31290)
    Then we run this script, when it asks for the steamid, give it 31290,
    this will install d3dcompiler_47.dll using protontricks,
    it will also try to change the DLL overrides for dxgi / d3d9 by editing the user.reg file,
    if automatically editing the user.reg fails, you will instructed how to do this process manually.
    
    Then we must find the directory which contains the exe file for the game, you can find it using the Steam client by
    right clicking the game, click Properties, click Local Files, clicking Browse, or by finding
    it using the command line: find ~/.local -iname 'Back to the future*'
    Then we get /home/kevin/.local/share/Steam/steamapps/common/Back to the Future Ep 1
    Sometimes the exe file is not in the main folder, you might have to look in subdirectories.
    
    Finally we are asked to run the game, set the paths to the folders in the ReShade settings for the Effects / Textures.
DESCRIPTION
MAIN_PATH=${MAIN_PATH:-~/.reshade}
RESHADE_PATH="$MAIN_PATH/reshade"
echo "ReShade installer/updater for Steam and proton on Linux."
mkdir -p "$MAIN_PATH"
cd "$MAIN_PATH"
if [[ ! -d reshade-shaders ]]; then
    echo -e "Installing reshade shaders.\n------------------------------------------------------------------------------------------------"
	git clone --branch master https://github.com/crosire/reshade-shaders || exit 1
else
    echo -e "Updating reshade shaders.\n------------------------------------------------------------------------------------------------"
    cd reshade-shaders
    git pull || exit 1
    cd "$MAIN_PATH"
fi
echo "------------------------------------------------------------------------------------------------"
mkdir -p "$RESHADE_PATH"
VERS=0
if [[ -e VERS ]]; then
    VERS=$(cat VERS)
fi
echo -e "Checking for Reshade updates.\n------------------------------------------------------------------------------------------------"
RVERS=$(curl -s https://reshade.me | grep -Po "downloads/\S+?\.exe" || exit 1)
if [[ $RVERS != $VERS ]]; then
    echo -e "Updating Reshade."
    tmpDir=$(mktemp -d || exit 1)
    cd "$tmpDir"
    wget -q https://reshade.me/"$RVERS" || exit 1
    exeFile="$(find . -name *.exe || exit 1)"
    7z -y e "$exeFile" 1> /dev/null || exit 1
    mv *32.dll d3d9.dll
    mv *64.dll dxgi.dll
    rm -f "$exeFile"
    rm -rf "$RESHADE_PATH"/*
    mv * "$RESHADE_PATH/"
    cd "$MAIN_PATH"
    rm -rf VERS
    echo "$RVERS" > VERS
    rm -rf "$tmpDir"
fi
echo "------------------------------------------------------------------------------------------------"
echo -e "Installing d3dcompiler_47 and setting dxgi override. Make sure to run the game at least once for steam to create the appropriate directories.\n------------------------------------------------------------------------------------------------"
echo 'Supply the steamid of the game to install d3dcompiler_47 (To find the steamid, run: protontricks -s Name_Of_Game). (Control+c to exit)'
echo "Enter n to skip this if d3dcompiler_47 is already installed and dxgi override is already set."
while true; do
    read -p 'steamid: ' steamid
    if [[ $steamid =~ ^([0-9]*|n|no|N|NO)$ ]]; then
        break
    fi
done
echo "------------------------------------------------------------------------------------------------"
if [[ $steamid =~ ^[0-9]*$ ]]; then
    protontricks $steamid d3dcompiler_47
    regFile=~/".local/share/Steam/steamapps/compatdata/$steamid/pfx/user.reg"
    if [[ -e $regFile ]] && [[ $(grep -Po '^"dxgi"="native,builtin"' $regFile) == "" ]]; then
        sed -i 's/^"\*d3dcompiler_47"="native"/\0\n"dxgi"="native,builtin"\n"d3d9"="native,builtin"/' "$regFile"
    fi
    if [[ ! -e $regFile ]] || [[ $(grep -Po '^"dxgi"="native,builtin"' $regFile) == "" ]]; then
        echo "Could not modify or find user.reg file: \"$regFile\""
        echo -e "Manually run: protontricks $steamid winecfg\nIn the Libraries tab, Add dxgi.dll and d3d9.dll and make sure they are set to \"native,builtin\"."
    fi
fi
echo -e "Installing reshade to game directory.\n------------------------------------------------------------------------------------------------"
echo 'Supply the folder path where the main executable (exe fle) for the game is. (On default steam settings, look in ~/.local/share/Steam/steamapps/common/) (Control+c to exit)'
while true; do
    read -p 'Game path: ' gamePath
    ls "$gamePath" > /dev/null 2>&1
    if [[ $? != 0 ]] || [[ -z $gamePath ]]; then
        echo "Incorrect or empty path supplied."
        continue
    fi
    echo "Is this correct? \"$gamePath\""
    read -p '(y/n): ' ynCheck
    if [[ $ynCheck =~ ^(y|Y|yes|YES)$ ]]; then
        break
    fi
done
gamePath="$(realpath "$gamePath")"
ln -is $(realpath ~/.reshade/reshade/*) "$gamePath/"
ln -is $(realpath ~/.reshade/reshade-shaders/Textures) "$gamePath/"
ln -is $(realpath ~/.reshade/reshade-shaders/Shaders) "$gamePath/"
echo "------------------------------------------------------------------------------------------------"
echo -e "Done.\nWhen you start the game for the first time, open the ReShade settings, go to the 'Settings' tab, add the Shaders folder location to the 'Effect Search Paths', add the Textures folder to the 'Texture Search Paths', go to the 'Home' tab, click 'Reload'."
