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

        SHADER_REPOS
            List of git repo URI's to clone / update with reshade shaders.
            By default this is set to :
                https://github.com/CeeJayDK/SweetFX|sweetfx-shaders;https://github.com/martymcmodding/qUINT|martymc-shaders;https://github.com/BlueSkyDefender/AstrayFX|astrayfx-shaders;https://github.com/prod80/prod80-ReShade-Repository|prod80-shaders;https://github.com/crosire/reshade-shaders|reshade-shaders|master
            The format is (the branch is optional) : URI|local_repo_name|branch
            Use ; to seperate multiple URL's. For example: URI1|local_repo_name_1|master;URI2|local_repo_name_2

        MERGE_SHADERS
            If you're using multiple shader repositories, all the unique shaders will be put into one folder called Merged.
            For example, if you use reshade-shaders and sweetfx-shaders, both have ASCII.fx,
            by enabling MERGE_SHADERS, only 1 ASCII.fx is put into the Merged folder.
            The order of importance for shaders is taken from SHADER_REPOS.
            Default is MERGE_SHADERS=1
            To disable, set MERGE_SHADERS=0

        REBUILD_MERGE
            Set to 1 to rebuild the MERGE_SHADERS folder.
            Useful if you change SHADER_REPOS

        GLOBAL_INI
            By default, the script will link a ReShade.ini file to the game's path.
            The ReShade.ini is stored in the MAIN_PATH folder.
            If you have disabled MERGE_SHADERS, you will need to manually edit the paths in ReShade.ini
            You can disable GLOBAL_INI with : GLOBAL_INI=0
            Disabling this will cause ReShade to create a ReShade.ini file when the game starts.
            You can use a different ReShade.ini (put them in the MAIN_PATH folder) by
            passing the name in the variable: GLOBAL_INI="ReShade2.ini"

        VULKAN_SUPPORT
            As noted below, Vulkan / ReShade is not currently functional under wine.
            The script contains a function to enable ReShade under Vulkan, although it's disabled
            by default since it's currently not functional, you can enable this function by
            passing VULKAN_SUPPORT=1

    Requirements:
        grep
        7z
        wget
        git
        wine (If the game uses Vulkan.)

    Notes:
        Vulkan / ReShade currently is not functional under wine.
        It might become possible in the future, so this information is provided in the event that happens.
        See https://github.com/kevinlekiller/reshade-steam-proton/issues/6
            Vulkan games like Doom (2016) : When asked if the game uses the Vulkan API, type y.
            Tell the script if the executable is 32 bit or 64 bit (by using the file command on the exe file or check on https://www.pcgamingwiki.com)
            Provide the WINEPREFIX to the script, for Steam games, the WINEPREFIX's folder name is the App ID and is stored in ~/.local/share/Steam/steamapps/compatdata/
            For example, on Doom (2016) on Steam, the WINEPREFIX is ~/.local/share/Steam/steamapps/compatdata/379720

        OpenGL games like Wolfenstein: The New Order, require the dll to be named opengl32.dll
        You will want to respond 'n' when asked for automatic detection of the dll.
        Then you will write 'opengl32' when asked for the name of the dll to override.
        You can check on pcgamingwiki.com to see what graphic API the game uses.

        Some games like Leisure Suit Larry: Wet Dreams Don't Dry have a 32 bit exe but use Direct3D 11,
        you'll have to manually specify the architecture (32) and DLL name (dxgi).

        Adding shader files not in a repository to the Merged/Shaders folder:
            For example, if we want to add this shader (CMAA2.fx) https://gist.github.com/martymcmodding/aee91b22570eb921f12d87173cacda03
            Create the External_shaders folder inside the MAIN_PATH folder (by default ~/.reshade)
            Add the shader to it: cd ~/.reshade/External_shaders && wget https://gist.githubusercontent.com/martymcmodding/aee91b22570eb921f12d87173cacda03/raw/CMAA2.fx
            Run this script, the shader will then be linked to the Merged folder.

        When you enable shaders in Reshade, this is a rough ideal order of shaders :
            color -> contrast/brightness/gamma -> anti-aliasing -> sharpening

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

        Installing ReShade for a DirectX / OpenGL game:
            Example on Back To The Future Episode 1:

                Find the game directory where the .exe file is.
                    If using Steam, you can open the Steam client, right click the game, click Properties,
                    click Local Files, clicking Browse, find the directory with the main
                    exe file, copy it, supply it to the script.

                    Or you can run : find ~/.local -iname 'Back to the future*'
                    Then run : ls "/home/kevin/.local/share/Steam/steamapps/common/Back to the Future Ep 1"
                    We see BackToTheFuture101.exe is in this directory.

                Run this script: ./reshade-linux.sh

                Type n when asked if the game uses the Vulkan API.

                Type i to install ReShade.
                    If you have never run this script, the shaders and ReShade will be downloaded.

                Supply the game directory where exe file is, when asked:
                    /home/kevin/.local/share/Steam/steamapps/common/Back to the Future Ep 1

                Select if you want it to automatically detect the correct dll file for ReShade or
                to manually specity it.

                Set the WINEDLLOVERRIDES environment variable as instructed.

                Run the game, set the Effects and Textures search paths in the ReShade settings if required.

        Uninstalling ReShade for a DirectX /OpenGL game:
            Run this script: ./reshade-linux.sh

            Type n when asked if the game uses the Vulkan API.

            Type u to uninstall ReShade.

            Supply the game path where the .exe file is (see instructions above).

        Installing ReShade for a Vulkan game:
            Example on Doom (2016) on Steam:

                Run this script ./reshade-linux.sh

                When asked if the game is using the Vulkan API, type y

                Supply the WINEPREFIX:
                To find the WINEPREFIX for Doom on Steam, do a search on https://steamdb.info for Doom : https://steamdb.info/app/379720/
                We see the App ID listed there as 379720, we can now search for the folder: find ~/.local/share/Steam -wholename *compatdata/379720
                    /home/kevin/.local/share/Steam/steamapps/compatdata/379720

                Supply the exe architecture (32 or 64 bits):
                To find the exe architecture for the game, we can run: file ~/.local/share/Steam/steamapps/common/DOOM/DOOMx64vk.exe
                    /home/kevin/.local/share/Steam/steamapps/common/DOOM/DOOMx64vk.exe: PE32+ executable (GUI) x86-64, for MS Windows
                x86-64 is 64 bits, Intel 80386 would be 32 bits.

                Type i when asked if you want to install ReShade.

        Uninstall ReShade for a Vulkan game:
                Run this script ./reshade-linux.sh

                Type y when asked if the game is using the Vulkan API.

                Supply the WINEPREFIX location and the exe architecture.

                Type u to uninstall ReShade.

        Removing ReShade / shader files:
            By default the files are stored in ~/.reshade
            Run: rm -rf ~/.reshade
DESCRIPTION

function printErr() {
    removeTempDir
    echo -e "\e[40m\e[31mError: $1\nExiting.\e[0m"
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
    [[ $1 -eq 32 ]] && hash="d6edb4ff0a713f417ebd19baedfe07527c6e45e84a6c73ed8c66a33377cc0aca" || hash="721977f36c008af2b637aedd3f1b529f3cfed6feb10f68ebe17469acb1934986"
    ffhash=$(sha256sum Firefox*.exe | cut -d\  -f1)
    if [[ "$ffhash" != "$hash" ]]; then
        printErr "(downloadD3dcompiler_47) Firefox integrity check failed. (Expected: $hash ; Calculated: $ffhash)"
    fi
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
MERGE_SHADERS=${MERGE_SHADERS:-1}

SHADER_REPOS=${SHADER_REPOS:-"https://github.com/CeeJayDK/SweetFX|sweetfx-shaders;https://github.com/martymcmodding/qUINT|martymc-shaders;https://github.com/BlueSkyDefender/AstrayFX|astrayfx-shaders;https://github.com/prod80/prod80-ReShade-Repository|prod80-shaders;https://github.com/crosire/reshade-shaders|reshade-shaders|master"}

if [[ -n $SHADER_REPOS ]]; then
    for URI in $(echo "$SHADER_REPOS" | tr ';' '\n'); do
        localRepoName=$(echo "$URI" | cut -d'|' -f2)
        branchName=$(echo "$URI" | cut -d'|' -f3)
        URI=$(echo "$URI" | cut -d'|' -f1)
        if [[ -d "$MAIN_PATH/ReShade_shaders/$localRepoName" ]]; then
            if [[ ! $UPDATE_RESHADE -eq 1 ]]; then
                continue
            fi
            cd "$MAIN_PATH/ReShade_shaders/$localRepoName" || continue
            echo "Updating ReShade shader repository $URI."
            git pull || echo "Could not update shader repo: $URI."
            continue
        fi
        cd "$MAIN_PATH/ReShade_shaders" || exit
        [[ -n $branchName ]] && branchName="--branch $branchName" || branchName=
        eval git clone "$branchName" "$URI" "$localRepoName" || echo "Could not clone Shader repo: $URI."
    done
    if [[ $MERGE_SHADERS == 1 ]]; then
        if [[ $REBUILD_MERGE == 1 ]]; then
            rm -rf "$MAIN_PATH/ReShade_shaders/Merged/"
        fi
        mkdir -p "$MAIN_PATH/ReShade_shaders/Merged/Shaders"
        mkdir -p "$MAIN_PATH/ReShade_shaders/Merged/Textures"
        for URI in $(echo "$SHADER_REPOS" | tr ';' '\n'); do
            localRepoName=$(echo "$URI" | cut -d'|' -f2)
            if [[ ! -d "$MAIN_PATH/ReShade_shaders/$localRepoName/Shaders" ]]; then
                continue
            fi
            cd "$MAIN_PATH/ReShade_shaders/$localRepoName/Shaders" || continue
            for file in *; do
                if [[ -L "$MAIN_PATH/ReShade_shaders/Merged/Shaders/$file" ]]; then
                    continue
                fi
                ln -s "$(realpath "$MAIN_PATH/ReShade_shaders/$localRepoName/Shaders/$file")" "$MAIN_PATH/ReShade_shaders/Merged/Shaders/"
            done
            if [[ ! -d "$MAIN_PATH/ReShade_shaders/$localRepoName/Textures" ]]; then
                continue
            fi
            cd "$MAIN_PATH/ReShade_shaders/$localRepoName/Textures" || continue
            for file in *; do
                if [[ -L "$MAIN_PATH/ReShade_shaders/Merged/Textures/$file" ]]; then
                    continue
                fi
                ln -s "$(realpath "$MAIN_PATH/ReShade_shaders/$localRepoName/Textures/$file")" "$MAIN_PATH/ReShade_shaders/Merged/Textures/"
            done
        done
        if [[ -d "$MAIN_PATH/External_shaders" ]]; then
            cd "$MAIN_PATH/External_shaders" || exit
            for file in *; do
                if [[ -L "$MAIN_PATH/ReShade_shaders/Merged/Shaders/$file" ]]; then
                    continue
                fi
                ln -s "$(realpath "$MAIN_PATH/External_shaders/$file")" "$MAIN_PATH/ReShade_shaders/Merged/Shaders/"
            done
        fi
    fi
fi

cd "$MAIN_PATH" || exit

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

WINE_MAIN_PATH="$(echo "$MAIN_PATH" | sed "s#/home/$USER/##" | sed 's#/#\\\\#g')"

VULKAN_SUPPORT=${VULKAN_SUPPORT:-0}
if [[ $VULKAN_SUPPORT == 1 ]]; then
    echo "Does the game use the Vulkan API?"
    if [[ $(checkStdin "(y/n): " "^(y|n)$") == "y" ]]; then
        echo 'Supply the WINEPREFIX path for the game.'
        echo '(Control+c to exit)'
        while true; do
            read -rp 'WINEPREFIX path: ' WINEPREFIX
            eval WINEPREFIX="$WINEPREFIX"
            WINEPREFIX=$(realpath "$WINEPREFIX")

            if ! ls "$WINEPREFIX" > /dev/null 2>&1 || [[ -z $WINEPREFIX ]]; then
                echo "Incorrect or empty path supplied. You supplied \"$WINEPREFIX\"."
                continue
            fi
            echo "Is this path correct? \"$WINEPREFIX\""
            if [[ $(checkStdin "(y/n) " "^(y|n)$") == "y" ]]; then
                break
            fi
        done
        echo "Specify if the game's EXE file architecture is 32 or 64 bits:"
        [[ $(checkStdin "(32/64) " "^(32|64)$") == 64 ]] && exeArch=64 || exeArch=32
        export WINEPREFIX="$WINEPREFIX"
        echo "Do you want to (i)nstall or (u)ninstall ReShade?"
        if [[ $(checkStdin "(i/u): " "^(i|u)$") == "i" ]]; then
            wine reg ADD HKLM\\SOFTWARE\\Khronos\\Vulkan\\ImplicitLayers /d 0 /t REG_DWORD /v "Z:\\home\\$USER\\$WINE_MAIN_PATH\\reshade\\ReShade$exeArch.json" -f /reg:$exeArch
        else
            wine reg DELETE HKLM\\SOFTWARE\\Khronos\\Vulkan\\ImplicitLayers -f /reg:$exeArch
        fi
        [[ $? == 0 ]] && echo "Done." || echo "An error has occured."
        if [[ ! -f $RESHADE_PATH/ReShade64.dll ]]; then
            cp -f "$(realpath "$RESHADE_PATH"/dxgi.dll)" "$RESHADE_PATH/ReShade64.dll"
        fi
        if [[ ! -f $RESHADE_PATH/ReShade32.dll ]]; then
            cp -f "$(realpath "$RESHADE_PATH"/d3d9.dll)" "$RESHADE_PATH/ReShade32.dll"
        fi
        exit 0
    fi
fi

echo "Do you want to (i)nstall or (u)ninstall ReShade for a DirectX or OpenGL game?"
if [[ $(checkStdin "(i/u): " "^(i|u)$") == "u" ]]; then
    getGamePath
    echo "Unlinking ReShade files."
    LINKS="$(echo "$COMMON_OVERRIDES" | sed 's/ /.dll /g' | sed 's/$/.dll/') ReShade32.json ReShade64.json d3dcompiler_47.dll Shaders Textures ReShade_shaders"
    for link in $LINKS; do
        if [[ -L $gamePath/$link ]]; then
            echo "Unlinking \"$gamePath/$link\"."
            unlink "$gamePath/$link"
        fi
    done

    echo "Finished uninstalling ReShade for '$gamePath'."
    echo -e "\e[40m\e[32mMake sure to remove or change the \e[34mWINEDLLOVERRIDES\e[32m environment variable.\e[0m"
    exit 0
fi

mkdir -p ReShade_shaders
mkdir -p External_shaders
cd "$MAIN_PATH/ReShade_shaders" || exit

getGamePath

echo "Do you want $0 to attempt to automatically detect the right dll files to use for ReShade?"

[[ $(checkStdin "(y/n) " "^(y|n)$") == "y" ]] && wantedDll="auto" || wantedDll="manual"

exeArch=32
if [[ $wantedDll == "auto" ]]; then
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
else
    echo "Specify if the game's EXE file architecture is 32 or 64 bits:"
    if [[ $(checkStdin "(32/64) " "^(32|64)$") == 64 ]]; then
        exeArch=64
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

downloadD3dcompiler_47 "$exeArch"

echo "Linking ReShade files to game directory."

if [[ -L $gamePath/$wantedDll.dll ]]; then
    unlink "$gamePath/$wantedDll.dll"
fi
if [[ $exeArch == 32 ]]; then
    echo "Linking d3d9.dll to $wantedDll.dll."
    ln -is "$(realpath "$RESHADE_PATH"/d3d9.dll)" "$gamePath/$wantedDll.dll"
else
    echo "Linking dxgi.dll to $wantedDll.dll."
    ln -is "$(realpath "$RESHADE_PATH"/dxgi.dll)" "$gamePath/$wantedDll.dll"
fi

if [[ -L $gamePath/d3dcompiler_47.dll ]]; then
    unlink "$gamePath/d3dcompiler_47.dll"
fi
ln -is "$(realpath "$MAIN_PATH/d3dcompiler_47.dll.$exeArch")" "$gamePath/d3dcompiler_47.dll"
ln -is "$(realpath "$RESHADE_PATH"/ReShade32.json)" "$gamePath/"
ln -is "$(realpath "$RESHADE_PATH"/ReShade64.json)" "$gamePath/"
ln -is "$(realpath "$MAIN_PATH"/ReShade_shaders)" "$gamePath/"

GLOBAL_INI=${GLOBAL_INI:-"ReShade.ini"}
if [[ $GLOBAL_INI != 0 ]] && [[ $GLOBAL_INI == ReShade.ini ]] && [[ ! -f $MAIN_PATH/$GLOBAL_INI ]]; then
    cd "$MAIN_PATH" || exit
    wget https://github.com/kevinlekiller/reshade-steam-proton/raw/ini/ReShade.ini
    if [[ -f ReShade.ini ]]; then
        sed -i "s/_USERSED_/$USER/g" "$MAIN_PATH/$GLOBAL_INI"
        if [[ $MERGE_SHADERS == 1 ]]; then
            sed -i "s#_SHADSED_#$WINE_MAIN_PATH\\\ReShade_shaders\\\Merged\\\Shaders#g" "$MAIN_PATH/$GLOBAL_INI"
            sed -i "s#_TEXSED_#$WINE_MAIN_PATH\\\ReShade_shaders\\\Merged\\\Textures#g" "$MAIN_PATH/$GLOBAL_INI"
        fi
    fi
fi
if [[ $GLOBAL_INI != 0 ]] && [[ -f $MAIN_PATH/$GLOBAL_INI ]]; then
    if [[ -L $gamePath/$GLOBAL_INI ]]; then
        unlink "$gamePath/$GLOBAL_INI"
    fi
    ln -is "$(realpath "$MAIN_PATH/$GLOBAL_INI")" "$gamePath/$GLOBAL_INI"
fi

echo -e "$SEPERATOR\nDone."
gameEnvVar="WINEDLLOVERRIDES=\"d3dcompiler_47=n;$wantedDll=n,b\""
echo -e "\e[40m\e[32mIf you're using Steam, right click the game, click properties, set the 'LAUNCH OPTIONS' to: \e[34m$gameEnvVar %command%"
echo -e "\e[32mIf not, run the game with this environment variable set: \e[34m$gameEnvVar"
echo -e "\e[32mThe next time you start the game, \e[34mopen the ReShade settings, go to the 'Settings' tab, if they are missing, add the Shaders folder" \
        "location to the 'Effect Search Paths', add the Textures folder to the 'Texture Search Paths'," \
        "these folders are located inside the ReShade_shaders folder, finally go to the 'Home' tab, click 'Reload'.\e[0m"
