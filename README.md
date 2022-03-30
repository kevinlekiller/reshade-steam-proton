# reshade-linux
Bash script to download ReShade and the shaders and link them to games running with wine or proton on Linux.  

## Usage

### Quick:
Download the script:

    curl -LO https://github.com/kevinlekiller/reshade-steam-proton/raw/main/reshade-linux.sh
Make it executable:

    chmod u+x reshade-linux.sh
Execute the script:

    ./reshade-linux.sh

### Detailed:
For detailed usage, follow the instructions in the script's source:

https://github.com/kevinlekiller/reshade-steam-proton/blob/main/reshade-linux.sh#L21

## Alternatives

### vkBasalt:
https://github.com/DadSchoorse/vkBasalt

For native Linux Vulkan games, Windows games which can run through DXVK (D3D9 / D3D10 / D3D11) and Windows games which can run through VKD3D (D3D12).

### vkBasalt through Gamescope:

Since [gamescope](https://github.com/Plagman/gamescope/) can use Vulkan, you can run vkBasalt on gamescope itself, instead of on the game, only issue is gamescope doesn't work with many games I've tried, but that will improve with time.

### kwin-effect-shaders:
https://github.com/kevinlekiller/kwin-effect-shaders

Works on any game.

## Misc
`reshade-linux.sh` is a newer script which works with any Windows game running under wine or proton.  
`reshade-steam-proton.sh` is a older script which relies on protontricks / only works with Steam.
