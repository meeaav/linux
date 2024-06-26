#!/bin/bash

stockage="/var/tmp/list_suid_sgid"
new_list="$stockage/new_list.txt"
last_list="$stockage/last_list.txt"
log="log.txt"

mkdir -p "$stockage"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Script executed: ./sguidList.sh" >> "$log"
find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -ld {} \; 2>>"$log" | awk '{print $1, $9}' > "$new_list" 2>>"$log"

if [ -f "$last_list" ]; 
then
    DIFF=$(diff "$last_list" "$new_list")
    if [ -n "$DIFF" ]; 
    then
        echo -e "Avertissement : La liste des fichiers ayant les droits SUID/SGID a changé. \nVoici les différences :\n"
        while IFS= read -r line; 
        do
            if [[ $line == "<"* ]]; 
            then
                droit=$(echo "$line" | awk '{print $2}')
                fichier=$(echo "$line" | awk '{print $3}')
                if [[ $droit == *s* ]]; 
                then
                    echo "- Le droit SUID a été enlevé sur \"$fichier\""
                elif [[ $droit == *S* ]]; 
                then
                    echo "- Le droit SGID a été enlevé sur \"$fichier\""
                fi
            elif [[ $line == ">"* ]]; 
            then
                droit=$(echo "$line" | awk '{print $2}')
                fichier=$(echo "$line" | awk '{print $3}')
                if [[ $droit == *s* ]]; 
                then
                    echo "- Le droit SUID a été ajouté sur \"$fichier\""
                elif [[ $droit == *S* ]]; 
                then
                    echo "- Le droit SGID a été ajouté sur \"$fichier\""
                fi
            fi
        done <<< "$DIFF"
    else
        echo "Aucun changement trouvé."
    fi
else
    echo "C'est la première fois que le script est lancé."
fi

cp "$new_list" "$last_list" 2>>"$log"
