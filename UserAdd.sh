#!/bin/bash
log="log.txt"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Script executed: ./userAdd.sh" >> "$log"

if [ ! -f "$1" ]; 
then
    echo "Il vous faut absolument mettre un fichier en paramètre"
    exit 1
fi
if [ ! -r "$1" ]; 
then
    echo "Impossible de lire le fichier $1"
    exit 1
fi
TMP_SU=$(mktemp)

while IFS=: read -r prenom nom groupes sudo mdp; 
do
    login=$(echo "${prenom:0:1}${nom}" | tr '[:upper:]' '[:lower:]')
    if [ -z "$prenom" ] || [ -z "$nom" ] || [ -z "$groupes" ] || [ -z "$sudo" ] || [ -z "$mdp" ]; 
    then
        echo "Ligne invalide dans le fichier $1"
        continue
    fi

    if id -u "$login" >>"$log" 2>&1;
    then
        i=1
        while id -u "$login$i" >> "$log" 2>&1;
        do
            ((i++))
        done
        login="$login$i"
    fi

    IFS=',' read -ra grp_tab <<< "$groupes"
    grp_prim="${grp_tab[0]}"
    grps_nd=("${grp_tab[@]:1}")

    if ! getent group "$grp_prim" >>"$log" 2>&1;
    then
        groupadd "$grp_prim"
    fi

    for grp in "${grps_nd[@]}"; 
    do
        if [ -n "$grp" ] && ! getent group "$grp" >>"$log" 2>&1;
        then
            groupadd "$grp"
        fi
    done

    if useradd -c "$prenom $nom" -m -s /bin/bash -g "$grp_prim" -G "$(IFS=,; echo "${grps_nd[*]}")" "$login"; 
    then
        echo "$login:$mdp" | chpasswd
        chage -d 0 "$login"

        if [ "$sudo" = "oui" ]; 
        then
            echo "$login ALL=(ALL) ALL" >> "$TMP_SU"
        fi

        nb=$((RANDOM % 10 + 1))
        for i in $(seq 1 $nb); 
        do
            file_size=$((RANDOM % 50 * 1024 * 1024 + 5 * 1024 * 1024))
            truncate -s "$file_size" "/home/$login/fichier$i"
        done

        echo "Utilisateur $login créé"
    else
        echo "Échec de la création de l'utilisateur $login" >> "$log"
    fi
done < "$1"

cat "$TMP_SU" >> /etc/sudoers
chmod 440 /etc/sudoers
rm "$TMP_SU"

exit 0
