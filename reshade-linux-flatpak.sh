#!/bin/bash

# Wrapper script for reshade-linux.sh for Steam installed from Flatpak.

cat > /dev/null <<LICENSE
    Copyright (C) 2023  kevinlekiller
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

RESHADE_LINUX=$(dirname "$(realpath "$0")")/reshade-linux.sh
[[ ! -f $RESHADE_LINUX ]] && echo "Unable to find reshade-linux.sh, exiting." && exit 1
chmod u+x "$RESHADE_LINUX"
export MAIN_PATH=~/.var/app/com.valvesoftware.Steam/.local/share/reshade
"$RESHADE_LINUX"
