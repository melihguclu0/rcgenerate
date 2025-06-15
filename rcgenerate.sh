#!/bin/bash
dash_help()
{
   echo
   echo "RCGenerate"
   echo "version 0.1"
   echo
   echo "This simple script is designed to assist in creating a KDEConnect \"Run Command\" configuration file, particularly helpful for Raspberry Pi setups without a monitor." 
   echo "Warning! Quotes need fixing in v0.1"
   echo "Use single quotes if you need enclosing something. Otherwise commands wont appear in other devices."
   echo
   echo "Usage: rcgenerate [options] name path"
   echo "options:"
   echo "  -n, --new       Add a new command"
   echo "  -i, --install   Generate and install configuration file"
   echo "  -r, --reset     Reset and install configuration file"
   echo "  -h, --help      Print this help"
   echo
   echo "Examples:"
   echo "  rcgenerate -n name path    Create a command with given name and path"
   echo "  rcgenerate -n              Prompt user for input"
   echo
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

gen_random(){
    random=$(openssl rand -hex 16)  
    echo "$random" | sed -E 's/(.{8})(.{4})(.{4})(.{4})(.{12})/\1_\2_\3_\4_\5/'
}

new_command() {
random=$(gen_random)

old_data=$(cat ${SCRIPT_DIR}/commands.json)
new_data=$(cat <<EOF
    {
    "_${random}_": {
            "command": "$path",
            "name": "$command"
            }
    }  
EOF
)

final_data=$(jq -n --argjson a "$new_data" --argjson b "$old_data" '$a + $b')
echo $final_data > ${SCRIPT_DIR}/commands.json
echo
echo "name:$command command:$path"
echo "New command added. Now run with -i to generate and install config file"
echo
exit 0
}

rst() 
{
read -p "Warning! This will overwrite your existing configuration. Proceed? Y/N" de
echo 

if [[ $de = "y" || $de = "Y" ]]; then

    :
elif [[ $de = "n" || $de = "N" ]]; then
    echo "Cancel"
    exit 1
else
    echo "Cancel"
    exit 1
fi

echo "Config Reset..."
random=$(gen_random)
#fix this double quotes
cat <<EOF > ${SCRIPT_DIR}/commands.json
{
"_${random}_": {
    "command": "echo 'Echo' >> /dev/pts/$(ps | grep -o 'pts/.' | cut -d'/' -f2 | head -n1)",
    "name": "echo"
    }
}
EOF

    generate
    echo "Done"
    exit 0
}

generate() {
    
    echo "Generating configuration file..."
    data=$(cat ${SCRIPT_DIR}/commands.json)
    h=$(echo $data | sed 's/"/\\"/g')

    while IFS= read -r line; do
        array+=("$line")
    done < <(kdeconnect-cli -l | grep -wEo "_?[a-zA-Z0-9]{8}_[a-zA-Z0-9]{4}_[a-zA-Z0-9]{4}_[a-zA-Z0-9]{4}_[a-zA-Z0-9]{12}_?")


    for element in "${array[@]}"; do
        echo -e "[General]\ncommands=\"@ByteArray(${h})\"" > "${HOME}/.config/kdeconnect/${element}/kdeconnect_runcommand/config"
    done
    echo "Done"
    exit 0
}



#Script Entry
if [[ $# > 3 ]]; then
    echo
    echo "Too many arguments"
    echo
    exit 2

else
    
   : #Do nothing and proceed
fi

if [[ $1 = "-r"  || $1 = "--reset" ]]; then

    rst

elif [[ $1 = "-n" || $1 = "--new" ]]; then
    

    if [[ -f ${SCRIPT_DIR}/commands.json ]]; then
        :
    else
        echo "No config file found"
        echo "Creating..."
        rst
    fi
    
    if [[ -n $2 ]] && [[ -n $3 ]]; then
        # If both $2 and $3 are not empty, use them
        command=$2
        path=$3
        
        new_command "$command" "$path"
    else
        # Otherwise, prompt the user for input
        read -p "Command name: " command
        read -p "Command path: " path
        new_command "$command" "$path"
    fi
    exit 0
    
elif [[ $1 = "-i" || $1 = "--install" ]]; then
    
    generate
    
elif [[ $1 = "" || $1 = "--help" ]]; then
    
    dash_help
    exit 0
else
    echo
    echo "Argument unknown. Try --help"
    exit 1
fi
