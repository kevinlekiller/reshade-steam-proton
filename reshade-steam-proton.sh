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
    
    To skip checking for ReShade / shader updates, set UPDATE_RESHADE=0
    
    To skip installing d3dcompiler_47, set D3DCOMPILER=0
    
    To use a custom dll override (instead of dxgi.dll) set CUSTOM_OVERRIDE=
    This will link dxgi.dll to the game using a different name, for example opengl32.dll and set a wine override for it.
    Example on a opengl game (Like Wolfenstein: The New Order): CUSTOM_OVERRIDE=opengl32 ./reshade-steam-proton.sh
    
    Requires grep, curl, 7z, wget, protontricks.
    
    NOTE: Overriding and installing the d3dcompiler_47 dll seems to occasionally fail with proton-ge under protontricks, switch
    to Steam's proton before running, you can switch back to proton-ge after.
    
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
function printErr() {
    echo -e "Error: $1\nExiting."
    exit 1
}
MAIN_PATH=${MAIN_PATH:-~/.reshade}
CUSTOM_OVERRIDE=${CUSTOM_OVERRIDE:-}
if [[ ! -z $CUSTOM_OVERRIDE ]] && [[ ! $CUSTOM_OVERRIDE =~ ^(opengl32|d3d11)$ ]]; then
    echo "You have entered '$CUSTOM_OVERRIDE' as the CUSTOM_OVERRIDE, is this correct?"
    read -p '(y/n): ' ynCheck
    if ! [[ $ynCheck =~ ^(y|Y|yes|YES)$ ]]; then
        echo "Exiting."
        exit 1
    fi
fi
UPDATE_RESHADE=${UPDATE_RESHADE:-1}
D3DCOMPILER=${D3DCOMPILER:-1}
RESHADE_PATH="$MAIN_PATH/reshade"
SEPERATOR="------------------------------------------------------------------------------------------------"
echo "ReShade installer/updater for Steam and proton on Linux."
mkdir -p "$MAIN_PATH" || printErr "Unable to create directory '$MAIN_PATH'."
cd "$MAIN_PATH"
if [[ ! -d reshade-shaders ]]; then
    echo -e "Installing reshade shaders.\n$SEPERATOR"
    git clone --branch master https://github.com/crosire/reshade-shaders || printErr "Unable to clone https://github.com/crosire/reshade-shaders"
elif [[ $UPDATE_RESHADE -eq 1 ]]; then
    echo -e "Updating reshade shaders.\n$SEPERATOR"
    cd reshade-shaders
    git pull || printErr "Could not update ReShade shaders."
    cd "$MAIN_PATH"
fi
echo "$SEPERATOR"
mkdir -p "$RESHADE_PATH"
VERS=0
if [[ -e VERS ]]; then
    VERS=$(cat VERS)
fi
if [[ ! -f reshade/dxgi.dll ]] || [[ $UPDATE_RESHADE -eq 1 ]]; then
    echo -e "Checking for Reshade updates.\n$SEPERATOR"
    RVERS=$(curl -s https://reshade.me | grep -Po "downloads/\S+?\.exe" || exit 1)
    if ! [[ $? -eq 0 ]]; then printErr "Could not fetch ReShade version."; fi
    if [[ $RVERS != $VERS ]]; then
        echo -e "Updating Reshade."
        tmpDir=$(mktemp -d || exit 1)
        cd "$tmpDir"
        wget -q https://reshade.me/"$RVERS" || printErr "Could not download latest version of ReShade."
        exeFile="$(find . -name *.exe || exit 1)"
        if ! [[ $? -eq 0 ]]; then printErr "Download of ReShade exe file failed."; fi
        7z -y e "$exeFile" 1> /dev/null || printErr "Failed to extract ReShade using 7z."
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
fi
echo -e "$SEPERATOR\nInstalling d3dcompiler_47 and setting dxgi override. Make sure to run the game at least once for steam to create the appropriate directories.\n$SEPERATOR"
echo 'Supply the steamid of the game to install d3dcompiler_47 (To find the steamid, run: protontricks -s Name_Of_Game). (Control+c to exit)'
echo "Enter n to skip this if d3dcompiler_47 is already installed and dxgi override is already set."
while true; do
    read -p 'steamid: ' steamid
    if [[ $steamid =~ ^([0-9]*|n|no|N|NO)$ ]]; then
        break
    fi
done
echo "$SEPERATOR"
if [[ $steamid =~ ^[0-9]*$ ]]; then
    if [[ $D3DCOMPILER -eq 1 ]]; then
        protontricks $steamid d3dcompiler_47
    fi
    regFile=~/".local/share/Steam/steamapps/compatdata/$steamid/pfx/user.reg"
    if [[ -z $CUSTOM_OVERRIDE ]]; then
        if [[ -e $regFile ]] && [[ $(grep -Po '^"dxgi"="native,builtin"' $regFile) == "" ]]; then
            echo "Adding dll overrides for d3d9 and dxgi."
            sed -i 's/^"\*d3dcompiler_47"="native"/\0\n"dxgi"="native,builtin"\n"d3d9"="native,builtin"/' "$regFile"
        fi
        if [[ ! -e $regFile ]] || [[ $(grep -Po '^"dxgi"="native,builtin"' $regFile) == "" ]]; then
            echo -e "Could not modify or find user.reg file: \"$regFile\"\nManually run: protontricks $steamid winecfg\nIn the Libraries tab, Add dxgi.dll and d3d9.dll and make sure they are set to \"native,builtin\"."
        fi
    fi
    if [[ ! -z $CUSTOM_OVERRIDE ]] && [[ -e $regFile ]] && [[ $(grep -Po "^\"$CUSTOM_OVERRIDE\"=\"native,builtin\"" $regFile) == "" ]]; then
        echo "Adding dll override for $CUSTOM_OVERRIDE."
        sed -i "s/^\"\*d3dcompiler_47\"=\"native\"/\0\n\"$CUSTOM_OVERRIDE\"=\"native,builtin\"/" "$regFile"
    fi
fi
echo -e "Installing reshade to game directory.\n$SEPERATOR"
echo 'Supply the folder path where the main executable (exe file) for the game is. (On default steam settings, look in ~/.local/share/Steam/steamapps/common/) (Control+c to exit)'
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
if ! [[ -z $CUSTOM_OVERRIDE ]]; then
    echo "Linking dxgi.dll as $CUSTOM_OVERRIDE.dll."
    ln -is $(realpath ~/.reshade/reshade/dxgi.dll) "$gamePath/$CUSTOM_OVERRIDE.dll"
fi
ln -is $(realpath ~/.reshade/reshade/*) "$gamePath/"
ln -is $(realpath ~/.reshade/reshade-shaders/Textures) "$gamePath/"
ln -is $(realpath ~/.reshade/reshade-shaders/Shaders) "$gamePath/"
echo -e "$SEPERATOR\nDone.\nWhen you start the game for the first time, open the ReShade settings, go to the 'Settings' tab, add the Shaders folder location to the 'Effect Search Paths', add the Textures folder to the 'Texture Search Paths', go to the 'Home' tab, click 'Reload'."
