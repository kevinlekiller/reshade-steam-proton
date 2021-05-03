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
    Bash script to download ReShade and the shaders and link them to games using wine or proton on Linux.
    By linking, we can re-run this script and all the games automatically get the newest ReShade and
    shader versions.
    
    Environment Variables:
        UPDATE_RESHADE
            To skip checking for ReShade / shader updates, set UPDATE_RESHADE=0 ; ex.: UPDATE_RESHADE=0 ./reshade-linux.sh
    
        MAIN_PATH
            By default, ReShade / shader files are stored in ~/.reshade
            You can override this by setting the MAIN_PATH variable, for example: MAIN_PATH=~/Documents/reshade ./reshade-linux.sh
    
    Reuirements:
        grep
        7z
        wget
        git
    
    Notes:
        OpenGL games like Wolfenstein: The New Order, require the dll to be named opengl32.dll
        You will want to respond 'n' when asked for automatic detection of the dll.
        Then you will write 'opengl32' when asked for the name of the dll to override.
        You can check on pcgamingwiki.com to see what graphic API the game uses.
    
    Usage:
        Download the script
            Using wget:
                wget https://github.com/kevinlekiller/reshade-steam-proton/raw/main/reshade-linux.sh
            Using git:
                git clone https://github.com/kevinlekiller/reshade-steam-proton
                cd reshade-steam-proton
        Make it executable:
            chmod u+x reshade-linux.sh
        Run it:
            ./reshade-linux.sh
        
        Installing ReShade for a game:
            Example on Back To The Future Episode 1:
                
                Find the game directory where the .exe file is.
                    If using Steam, you can open the Steam client, right click the game, click Properties,
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
                
                Set the 
                
                Run the game, set the Effects and Textures search paths in the ReShade settings.
            
        Uninstalling ReShade for a game:
            Run this script.
            
            Type u to uninstall ReShade.
            
            Supply the game path where the .exe file is (see instructions above).
            
        Removing ReShade / shader files:
            By default the files are stored in ~/.reshade
            Run: rm -rf ~/.reshade
DESCRIPTION

function printErr() {
    removeTempDir
    tput setab 0
    tput setaf 1
    echo -e "\e[40m\e[31mError: $1\nExiting.\e[0m"
    tput sgr0
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

function createTempDir() {
    tmpDir=$(mktemp -d)
    cd "$tmpDir" || printErr "Failed to create temp directory."
}

function removeTempDir() {
    cd "$MAIN_PATH" || exit
    if [[ -d $tmpDir ]]; then
        rm -rf "$tmpDir"
    fi
}

function downloadD3dcompiler_47() {
    if ! [[ $1 =~ ^(32|64)$ ]]; then
        printErr "(downloadD3dcompiler_47): Wrong system architecture."
    fi
    if [[ -f $MAIN_PATH/d3dcompiler_47.dll.$1 ]]; then
        return
    fi
    echo "Downloading d3dcompiler_47.dll for $1 bits."
    createTempDir
    # Based on https://github.com/Winetricks/winetricks/commit/bc5c57d0d6d2c30642efaa7fee66b60f6af3e133
    wget -q "https://download-installer.cdn.mozilla.net/pub/firefox/releases/62.0.3/win$1/ach/Firefox%20Setup%2062.0.3.exe" \
        || echo "Could not download Firefox setup file (which contains d3dcompiler_47.dll)"
    7z -y e Firefox*.exe 1> /dev/null || printErr "(dowloadD3dcompiler_47) Failed to extract Firefox using 7z."
    cp d3dcompiler_47.dll "$MAIN_PATH/d3dcompiler_47.dll.$1" || printErr "(downloadD3dcompiler_47): Unable to find d3dcompiler_47.dll"
    removeTempDir
}

SEPERATOR="------------------------------------------------------------------------------------------------"

COMMON_OVERRIDES="d3d8 d3d9 d3d11 ddraw dinput8 dxgi opengl32"

echo -e "$SEPERATOR\nReShade installer/updater for Linux games using wine or proton.\n$SEPERATOR\n"

MAIN_PATH=${MAIN_PATH:-~/".reshade"}
RESHADE_PATH="$MAIN_PATH/reshade"

mkdir -p "$MAIN_PATH" || printErr "Unable to create directory '$MAIN_PATH'."
cd "$MAIN_PATH" || exit

UPDATE_RESHADE=${UPDATE_RESHADE:-1}

echo "Do you want to (i)nstall or (u)ninstall ReShade for a game?"
if [[ $(checkStdin "(i/u): " "^(i|u)$") == "u" ]]; then
    getGamePath
    echo "Unlinking ReShade files."
    LINKS="$(echo "$COMMON_OVERRIDES" | sed 's/ /.dll /g' | sed 's/$/.dll/') ReShade32.json ReShade64.json d3dcompiler_47.dll Shaders Textures"
    for link in $LINKS; do
        if [[ -L $gamePath/$link ]]; then
            echo "Unlinking \"$gamePath/$link\"."
            unlink "$gamePath/$link"
        fi
    done
    
    echo "Finished uninstalling ReShade for '$gamePath'."
    echo -e "\e[5m\e[40m\e[32mMake sure to remove or change the WINEDLLOVERRIDES environment variable.\e[0m"
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
    RVERS=$(wget -qO - https://reshade.me | grep -Po "downloads/\S+?\.exe")
    if [[ $RVERS == "" ]]; then
        printErr "Could not fetch ReShade version."
    fi
    if [[ $RVERS != "$VERS" ]]; then
        echo -e "Updating Reshade."
        createTempDir
        wget  https://reshade.me/"$RVERS" || printErr "Could not download latest version of ReShade."
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
        removeTempDir
        echo "Updated ReShade to version $(echo "$RVERS" | grep -o '[0-9][0-9.]*[0-9]')."
        echo "$RVERS" > VERS
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

[[ $wantedDll == "d3d9" ]] && dllArch=32 || dllArch=64
downloadD3dcompiler_47 "$dllArch"

echo "Linking ReShade files to game directory."

if [[ $wantedDll == "d3d9" ]]; then
    ln -is "$(realpath "$RESHADE_PATH"/d3d9.dll)" "$gamePath/"
else
    echo "Linking dxgi.dll as $wantedDll.dll."
    ln -is "$(realpath "$RESHADE_PATH"/dxgi.dll)" "$gamePath/$wantedDll.dll"
fi

ln -is "$(realpath "$MAIN_PATH/d3dcompiler_47.dll.$dllArch")" "$gamePath/d3dcompiler_47.dll"
ln -is "$(realpath "$RESHADE_PATH"/ReShade32.json)" "$gamePath/"
ln -is "$(realpath "$RESHADE_PATH"/ReShade64.json)" "$gamePath/"
ln -is "$(realpath "$MAIN_PATH"/reshade-shaders/Textures)" "$gamePath/"
ln -is "$(realpath "$MAIN_PATH"/reshade-shaders/Shaders)" "$gamePath/"

echo -e "$SEPERATOR\nDone."
gameEnvVar="WINEDLLOVERRIDES=\"d3dcompiler_47=n;$wantedDll=n,b\""
echo -e "\e[40m\e[32mIf you're using Steam, right click the game, click properties, set the 'LAUNCH OPTIONS' to: \e[34m$gameEnvVar %command%"
echo -e "\e[32mIf not, run the game with this environment variable set: \e[34m$gameEnvVar"
echo -e "\e[32mThe next time you start the game, \e[34mopen the ReShade settings, go to the 'Settings' tab, add the Shaders folder" \
"location to the 'Effect Search Paths', add the Textures folder to the 'Texture Search Paths', go to the 'Home' tab, click 'Reload'.\e[0m"
