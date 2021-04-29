# reshade-steam-proton
Easy setup and updating of ReShade on Steam / Linux.

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
