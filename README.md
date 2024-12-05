# rcgenerate

Simple script to generate KDEConnect Run Command configuration file,
particularly helpful for Raspberry Pi setups without a display


## Requirements:
`jq` Command-line JSON processor
### Usage:

1.  `chmod +x rcgenerate`
2.  `./rcgenerate -r` Create initial configuration
3.  `./rcgenerate -n command_name command_path` Add new commands or edit "commands.json" file manually.
4.  `./rcgenerate -i` Generate and install configuration file
5.  Commands will appear shortly in other devices. Running `kdeconnect-cli --refresh` might speed up the process. 


### Known Problems:

Double quotes are problematic. Single quotes seem to work but probably makes variable expansion, command substitution etc. impossible.
