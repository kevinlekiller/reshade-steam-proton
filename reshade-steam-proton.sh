#!/bin/bash
cat > /dev/null <<LICENSE
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
cat > /dev/null <<DESCRIPTION
    Bash script to download ReShade and the shaders and link them to Steam games on Linux.
    By linking, we can re-run this script and all the games automatically get the newest ReShade and
    shader versions.
    
    Environment Variables:
        UPDATE_RESHADE
            To skip checking for ReShade / shader updates, set UPDATE_RESHADE=0 ; ex.: UPDATE_RESHADE=0 ./reshade-steam-proton.sh
    
        D3DCOMPILER
            To skip installing d3dcompiler_47, set D3DCOMPILER=0 ; ex.: D3DCOMPILER=0 ./reshade-steam-proton.sh
    
        MAIN_PATH
            By default, ReShade / shader files are stored in ~/.reshade
            You can override this by setting the MAIN_PATH variable, for example: MAIN_PATH=~/Documents/reshade ./reshade-steam-proton.sh
    
    Reuirements:
        grep
        curl
        7z
        wget
        protontricks
        git
    
    Notes:
        Overriding and installing the d3dcompiler_47 dll seems to occasionally fail with proton-ge under protontricks, switch
        to Steam's proton before running, you can switch back to proton-ge after.
        
        OpenGL games like Wolfenstein: The New Order, require the dll to be named opengl32.dll
        You will want to respond 'n' when asked for automatic detection of the dll.
        Then you will write 'opengl32' when asked for the name of the dll to override.
        You can check on pcgamingwiki.com to see what graphic API the game uses.
    
    Usage:
        Download the script
            Using wget:
                wget https://github.com/kevinlekiller/reshade-steam-proton/raw/main/reshade-steam-proton.sh
            Using git:
                git clone https://github.com/kevinlekiller/reshade-steam-proton
                cd reshade-steam-proton
        Make it executable:
            chmod u+x reshade-steam-proton.sh
        Run it:
            ./reshade-steam-proton.sh
        
        Installing ReShade for a game:
            Example on Back To The Future Episode 1:
            
                If the game has never been run, run it, steam will create the various required directories.
                Exit the game.
                
                Find the SteamID: protontricks -s Back To The Future
                    Back to the Future: Ep 1 - It's About Time (31290)
                
                Find the game directory where the .exe file is.
                    You can open the Steam client, right click the game, click Properties,
                    click Local Files, clicking Browse, find the directory with the main
                    exe file, copy it, supply it to the script.
                    
                    Or you can run : find ~/.local -iname 'Back to the future*'
                    Then run : ls "/home/kevin/.local/share/Steam/steamapps/common/Back to the Future Ep 1"
                    We see BackToTheFuture101.exe is in this directory.
                
                Run this script.
                
                Type i to install ReShade.
                    If you have never run this script, the shaders and ReShade will be downloaded.
                
                Supply the game directory where exe file is, when asked:
                    /home/kevin/.local/share/Steam/steamapps/common/Back to the Future Ep 1
                
                Select if you want it to automatically detect the correct dll file for ReShade or
                to manually specity it.
                
                Give it 31290 when asked for the SteamID
                
                If the automatic override of the dll fails, you will be
                instructed how to manually do it.
                
                Run the game, set the Effects and Textures search paths in the ReShade settings.
            
        Uninstalling ReShade for a game:
            Run this script.
            
            Type u to uninstall ReShade.
            
            Supply the game path where the .exe file is (see instructions above).
            
            Supply the SteamID for the game (see instructions above).
            
        Removing ReShade / shader files:
            By default the files are stored in ~/.reshade
            Run: rm -rf ~/.reshade
DESCRIPTION

function printErr() {
    if [[ -d $tmpDir ]]; then
        rm -rf "$tmpDir"
    fi
    echo -e "Error: $1\nExiting."
    [[ -z $2 ]] && exit 1 || exit "$2"
}

function checkStdin() {
    while true; do
        read -rp "$1" userInput
        if [[ $userInput =~ $2 ]]; then
            break
        fi
    done
    echo "$userInput"
}

function getGamePath() {
    echo 'Supply the folder path where the main executable (exe file) for the game is.'
    echo 'On default steam settings, look in ~/.local/share/Steam/steamapps/common/'
    echo '(Control+c to exit)'
    while true; do
        read -rp 'Game path: ' gamePath
        eval gamePath="$gamePath"
        gamePath=$(realpath "$gamePath")
        
        if ! ls "$gamePath" > /dev/null 2>&1 || [[ -z $gamePath ]]; then
            echo "Incorrect or empty path supplied. You supplied \"$gamePath\"."
            continue
        fi
        
        if ! ls "$gamePath/"*.exe > /dev/null 2>&1; then
            echo "No .exe file found in \"$gamePath\"."
            echo "Do you still want to use this directory?"
            if [[ $(checkStdin "(y/n) " "^(y|n)$") != "y" ]]; then
                continue
            fi
        fi
        
        echo "Is this path correct? \"$gamePath\""
        if [[ $(checkStdin "(y/n) " "^(y|n)$") == "y" ]]; then
            break
        fi
    done
}

function getSteamID() {
    echo 'Please supply the SteamID of the game (To find the SteamID, run: protontricks -s Name_Of_Game). (Control+c to exit)'
    SteamID=$(checkStdin "SteamID: " "^[0-9]*$")
}

function checkUserReg() {
    regFile=~/".local/share/Steam/steamapps/compatdata/$SteamID/pfx/user.reg"
    if [[ ! -f $regFile ]]; then
        echo "Could not modify or find user.reg file: \"$regFile\""
        regFile=
        echo "Manually run: protontricks $SteamID winecfg"
        echo "In the Libraries tab, $1."
        read -rp 'Press any key to continue.'
    fi
}

SEPERATOR="------------------------------------------------------------------------------------------------"

OVERRIDE_REGEX='"OVERRIDE"="native,builtin"'
COMMON_OVERRIDES="d3d8 d3d9 d3d11 ddraw dinput8 dxgi opengl32"

echo -e "$SEPERATOR\nReShade installer/updater for Steam and proton on Linux.\n$SEPERATOR\n"

MAIN_PATH=${MAIN_PATH:-~/".reshade"}
RESHADE_PATH="$MAIN_PATH/reshade"

mkdir -p "$MAIN_PATH" || printErr "Unable to create directory '$MAIN_PATH'."
cd "$MAIN_PATH" || exit

UPDATE_RESHADE=${UPDATE_RESHADE:-1}
D3DCOMPILER=${D3DCOMPILER:-1}

echo "Do you want to (i)nstall or (u)ninstall ReShade for a game?"
if [[ $(checkStdin "(i/u): " "^(i|u)$") == "u" ]]; then
    getGamePath
    getSteamID
    echo "Unlinking ReShade files."
    LINKS="$(echo "$COMMON_OVERRIDES" | sed 's/ /.dll /g' | sed 's/$/.dll/') ReShade32.json ReShade64.json Shaders Textures"
    for link in $LINKS; do
        if [[ -L $gamePath/$link ]]; then
            echo "Unlinking \"$gamePath/$link\"."
            unlink "$gamePath/$link"
        fi
    done
    
    echo "Removing dll overrides."
    checkUserReg "remove overrides for ${COMMON_OVERRIDES// /, })"
    if [[ -f $regFile ]]; then
        for override in $COMMON_OVERRIDES; do
            pattern=${OVERRIDE_REGEX//OVERRIDE/$override}
            if [[ $(grep -Po "$pattern" "$regFile") != "" ]]; then
                pattern="s/$pattern\n//g"
                echo "Removing dll override (sed -zi '$pattern' \"$regFile\")."
                sed -zi "$pattern" "$regFile"
            fi
        done
    fi
    echo "Finished uninstalling ReShade for SteamID $SteamID."
    exit 0
fi

if [[ ! -d reshade-shaders ]]; then
    echo -e "Installing reshade shaders.\n$SEPERATOR"
    git clone --branch master https://github.com/crosire/reshade-shaders || printErr "Unable to clone https://github.com/crosire/reshade-shaders"
elif [[ $UPDATE_RESHADE -eq 1 ]]; then
    echo -e "Updating reshade shaders.\n$SEPERATOR"
    cd reshade-shaders || printErr "reshade-shaders folder missing."
    git pull || printErr "Could not update ReShade shaders."
    cd "$MAIN_PATH" || exit
fi

echo "$SEPERATOR"
mkdir -p "$RESHADE_PATH"

[[ -f VERS ]] && VERS=$(cat VERS) || VERS=0

if [[ ! -f reshade/dxgi.dll ]] || [[ $UPDATE_RESHADE -eq 1 ]]; then
    echo -e "Checking for Reshade updates.\n$SEPERATOR"
    RVERS=$(curl -s https://reshade.me | grep -Po "downloads/\S+?\.exe")
    if [[ $RVERS == "" ]]; then
        printErr "Could not fetch ReShade version."
    fi
    if [[ $RVERS != "$VERS" ]]; then
        echo -e "Updating Reshade."
        tmpDir=$(mktemp -d)
        cd "$tmpDir" || printErr "Failed to create temp directory."
        wget -q https://reshade.me/"$RVERS" || printErr "Could not download latest version of ReShade."
        exeFile="$(find . -name "*.exe")"
        if ! [[ -f $exeFile ]]; then
            printErr "Download of ReShade exe file failed."
        fi
        7z -y e "$exeFile" 1> /dev/null || printErr "Failed to extract ReShade using 7z."
        mv ./*32.dll d3d9.dll
        mv ./*64.dll dxgi.dll
        rm -f "$exeFile"
        rm -rf "${RESHADE_PATH:?}"/*
        mv ./* "$RESHADE_PATH/"
        cd "$MAIN_PATH" || exit
        echo "$RVERS" > VERS
        rm -rf "$tmpDir"
    fi
fi

getGamePath

echo "Do you want $0 to attempt to automatically detect the right dll to use for ReShade?"

[[ $(checkStdin "(y/n) " "^(y|n)$") == "y" ]] && wantedDll="auto" || wantedDll="manual"

if [[ $wantedDll == "auto" ]]; then
    exeArch=32
    for file in "$gamePath/"*.exe; do
        if [[ $(file "$file") =~ x86-64 ]]; then
            exeArch=64
            break
        fi
    done
    [[ $exeArch -eq 32 ]] && wantedDll="d3d9" || wantedDll="dxgi"
    echo "We have detected the game is $exeArch bits, we will use $wantedDll.dll as the override, is this correct?"
    if [[ $(checkStdin "(y/n) " "^(y|n)$") == "n" ]]; then
        wantedDll="manual"
    fi
fi

if [[ $wantedDll == "manual" ]]; then
    echo "Manually enter the dll override for ReShade, common values are one of: $COMMON_OVERRIDES"
    while true; do
        read -rp 'Override: ' wantedDll
        wantedDll=${wantedDll//.dll/}
        echo "You have entered '$wantedDll', is this correct?"
        read -rp '(y/n): ' ynCheck
        if [[ $ynCheck =~ ^(y|Y|yes|YES)$ ]]; then
            break
        fi
    done
fi

getSteamID

if [[ $D3DCOMPILER -eq 1 ]]; then
    echo -e "$SEPERATOR\nInstalling d3dcompiler_47 using protontricks."
    protontricks "$SteamID" d3dcompiler_47
fi

checkUserReg "Add $wantedDll and make sure it is set to  \"native,builtin\"."

if [[ -f $regFile ]] && [[ $(grep -Po "^\"$wantedDll\"=\"native,builtin\"" "$regFile") == "" ]]; then
    echo "Adding dll override for $wantedDll."
    sed -i "s/^\"\*d3dcompiler_47\"=\"native\"/\0\n\"$wantedDll\"=\"native,builtin\"/" "$regFile"
fi

echo "Linking ReShade files to game directory."

if [[ $wantedDll == "d3d9" ]]; then
    ln -is "$(realpath "$RESHADE_PATH"/d3d9.dll)" "$gamePath/"
else
    echo "Linking dxgi.dll as $wantedDll.dll."
    ln -is "$(realpath "$RESHADE_PATH"/dxgi.dll)" "$gamePath/$wantedDll.dll"
fi

ln -is "$(realpath "$RESHADE_PATH"/ReShade32.json)" "$gamePath/"
ln -is "$(realpath "$RESHADE_PATH"/ReShade64.json)" "$gamePath/"
ln -is "$(realpath "$MAIN_PATH"/reshade-shaders/Textures)" "$gamePath/"
ln -is "$(realpath "$MAIN_PATH"/reshade-shaders/Shaders)" "$gamePath/"

echo -e "$SEPERATOR\nDone."
echo "The next time you start the game, open the ReShade settings, go to the 'Settings' tab, add the Shaders folder location to the 'Effect Search Paths', add the Textures folder to the 'Texture Search Paths', go to the 'Home' tab, click 'Reload'."
