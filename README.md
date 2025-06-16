# rcgenerate

Simple script to generate KDEConnect Run Command configuration file,
particularly helpful for Raspberry Pi setups without a display. Using this script, you can add new commands and synchronize across all connected devices easily. 

## Requirements:

`jq` Command-line JSON processor

### Usage:

1.  `chmod +x ./rcgenerate.sh`
2.  `./rcgenerate.sh -r` Reset and create the initial configuration
3.  `./rcgenerate.sh -g` Get existing configuration file
4.  `./rcgenerate.sh -n "command_name" "command_path"` Add new commands or edit
    "commands_${ID}.json" file manually.
5. `./rcgenerate.sh -s` Set existing configuration file
6.  As with the new random ID's assigned for each command - they will take a while to appear on the other devices. Running `kdeconnect-cli
    \--refresh` might speed up the process. On Android **Settings > Apps > KDEConnect > Force Close** then restart.

### Limitations:

- For now, its not possible to assign commands for individual device. New commands added globally.

### Known Problems:

Double quotes are problematic. Single quotes seem to work but probably makes
variable expansion, command substitution etc. impossible.

