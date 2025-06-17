#!/bin/bash
dash_help()
{
   echo
   echo "RCGenerate"
   echo "version 0.5"
   echo
   echo "This simple script is designed to assist in creating a KDEConnect \"Run Command\" configuration file, particularly helpful for Raspberry Pi setups without a monitor." 
   echo "Warning! Quotes need fixing"
   echo "Use single quotes if you need enclosing something. Otherwise commands may not appear in other devices."
   echo
   echo "Usage: rcgenerate [options] name path"
   echo "options:"
   echo "  -g, --get-current    Get current commands"
   echo "  -s, --set-current    Set current commands"
   echo "  -n, --add-command    Add a new command"
   echo "  -l, --list-devices   List remote devices"
   echo "  -r, --reset          Reset configuration"
   echo "  -h, --help           Print this help"
   echo
   echo "Examples:"
   echo "  rcgenerate -n name path    Create a command with given name and path"
   echo "  rcgenerate -n              Prompt user for input"
   echo
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

get_dev() {

while IFS= read -r line; do
    array+=("$line")
done < <(kdeconnect-cli -l | grep -wEo "_?[a-zA-Z0-9]{8}_[a-zA-Z0-9]{4}_[a-zA-Z0-9]{4}_[a-zA-Z0-9]{4}_[a-zA-Z0-9]{12}_?")
    echo ${array[@]}
}

gen_random(){
    random=$(openssl rand -hex 16)  
    echo "$random" | sed -E 's/(.{8})(.{4})(.{4})(.{4})(.{12})/\1_\2_\3_\4_\5/'
}


edit() {


    read -r -a DEV <<< "$(get_dev)"

    for i in ${DEV[@]}; do

    INPUT_FILE="${SCRIPT_DIR}/commands_$i.json"
    TMP_FILE="$(mktemp)"
    OUTPUT_FILE="$INPUT_FILE"  # Aynı dosyaya yazacağız ama geçici dosya üzerinden

    # ID'leri listele
    echo
    echo "Available entries for:"
    echo $i

    ids=($(jq -r 'keys[]' "$INPUT_FILE"))
    echo
    for i in "${!ids[@]}"; do
    name=$(jq -r --arg key "${ids[$i]}" '.[$key].name' "$INPUT_FILE")
    echo "$i) ${ids[$i]} - $name"
    done

    # Seçim al
    echo
    echo -n "Select the entry you wish to delete: "
    read selection

    # Kontrol
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 0 ] && [ "$selection" -lt "${#ids[@]}" ]; then
    selected_id="${ids[$selection]}"
    echo "Selected: $selected_id"

    # Sil -> geçici dosyaya yaz
    jq "del(.\"$selected_id\")" "$INPUT_FILE" > "$TMP_FILE"

    # Orijinal dosyayı güncelle
    mv "$TMP_FILE" "$OUTPUT_FILE"
    echo "Updated: $OUTPUT_FILE"
    else

        :
    fi
    done


}


new_command() {
random=$(gen_random)

read -r -a DEV <<< "$(get_dev)"

command=$(echo $command | sed 's/"/\\\"/g')
path=$(echo $path | sed 's/"/\\\"/g')
for i in "${DEV[@]}"; do
old_data=$(cat ${SCRIPT_DIR}/commands_$i.json)

new_data=$(cat <<EOF
    {
    "_${random}_": {
            "command": "$path",
            "name": "$command"
            }
    }  
EOF
)

data=$(jq -n --argjson a "$new_data" --argjson b "$old_data" '$a + $b')
echo $data > ${SCRIPT_DIR}/commands_$i.json
done
echo
echo "Added:"
echo "name: $command"
echo "path: $path"
echo
exit 0
}

reset()
{

echo "Resetting..."
random=$(gen_random)

read -r -a DEV <<< "$(get_dev)"

for i in "${DEV[@]}"; do
rm ${SCRIPT_DIR}/commands_$i.json 2> /dev/null
cat <<EOF > ${SCRIPT_DIR}/commands_$i.json
{
"_${random}_": {
    "command": "notify-send Ping!",
    "name": "Ping Device"
    }
}
EOF
done

    echo "Done"

}


read_current() {


    echo "Reading:"

    read -r -a DEV <<< "$(get_dev)"

for i in "${!DEV[@]}"; do
    config_file="${HOME}/.config/kdeconnect/${DEV[$i]}/kdeconnect_runcommand/config"

    escaped_json=$(grep '^commands="@ByteArray' "$config_file" | sed -E 's/^commands="@ByteArray\((.*)\)"$/\1/')

    cleaned_json=$(echo "$escaped_json" | sed 's/\\"/"/g')

    echo "$cleaned_json" | jq . > "${SCRIPT_DIR}/commands_${DEV[$i]}.json"

    echo "Created file:"
    echo "${SCRIPT_DIR}/commands_${DEV[$i]}.json"


done


    exit 23
}

install() {
    echo
    read -p "Warning! This will overwrite your existing configuration. Proceed? Y/N " de
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

    read -r -a DEV <<< "$(get_dev)"
    echo "Installing:"
    for i in "${DEV[@]}"; do
        echo "${HOME}/.config/kdeconnect/$i/kdeconnect_runcommand/config"
        data=$(cat ${SCRIPT_DIR}/commands_$i.json)
        h=$(echo $data | sed 's/"/\\\"/g')
        echo -e "[General]\ncommands=\"@ByteArray(${h})\"" > "${HOME}/.config/kdeconnect/$i/kdeconnect_runcommand/config"
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
    
    reset
    
elif [[ $1 = "-g" || $1 = "--get-current" ]]; then

    read_current

elif [[ $1 = "-e" || $1 = "--edit" ]]; then

    edit


elif [[ $1 = "-n" || $1 = "--add-new" ]]; then
    

read -r -a DEV <<< "$(get_dev)"

for i in "${DEV[@]}"; do
    file="${SCRIPT_DIR}/commands_${i}.json"

    if [[ -f "$file" ]]; then
        :
    else
        echo "Missing configuration files. Run with \"-r\""
        exit 1
    fi
done



    if [[ -n $2 ]] && [[ -n $3 ]]; then

        command=$2
        path=$3
        
        new_command "$command" "$path"
    else

        read -p "Command name: " command
        read -p "Command path: " path
        new_command "$command" "$path"
    fi
    exit 0
    
elif [[ $1 = "-s" || $1 = "--set-current" ]]; then
    
    install
    
elif [[ $1 = "" || $1 = "--help" ]]; then
    
    dash_help
    exit 0

elif [[ $1 = "-l" || "--list-devices" ]]; then

    read -r -a DEV <<< "$(get_dev)"
    for i in "${!DEV[@]}"; do
        echo "Device$i ID: ${DEV[$i]}"
    done

else
    echo
    echo "Argument unknown. Try --help"
    exit 1
fi
