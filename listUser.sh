#!/bin/bash
log="log.txt"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Script executed: ./userList.sh" >> "$log"
results=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        -G)
            grp_prim="$2"
            shift 2
            ;;
        -g)
            grp_nd="$2"
            shift 2
            ;;
        -s)
            is_sudoer="$2"
            shift 2
            ;;
        -u)
            user="$2"
            shift 2
            ;;
        *)
            echo "Option non valide: $1"
            exit 1
            ;;
    esac
done

users=$(cat /etc/passwd | grep "/home" | cut -d: -f1)
for i in $users; 
do
    groups=$(id -Gn "$i")
    readarray -d ' ' -t group_array <<< "$groups"

    if [[ -n "$grp_prim" ]]; 
    then
        user_grp_prim="${group_array[0]}"
        if [[ "$user_grp_prim" != "$grp_prim" ]]; 
        then
            continue
        fi
    fi

    if [[ -n "$grp_nd" ]]; 
    then
        user_grp_nds=("${group_array[@]:1}")
        group_found=false
        for grp in "${user_grp_nds[@]}"; 
        do
            if [[ "$grp" == "$grp_nd" ]] >> "$log":
            then
                group_found=true
                break
            fi
        done
        if [[ "$group_found" == false ]]; 
        then
            continue
        fi
    fi

    if [[ -n "$is_sudoer" ]]; 
    then
        if [[ "$is_sudoer" == "0" ]]; 
        then
            if sudo -l -U "$i" | grep -q "(ALL) ALL"; 
            then
                continue
            fi
        else
            if ! sudo -l -U "$i" | grep -q "(ALL) ALL"; 
            then
                continue
            fi
        fi
    fi

    if [[ -n "$user" ]]; 
    then
        if [[ "$i" != "$user" ]]; 
        then
            continue
        fi
    fi

    results=true
    full_name=$(grep "^$i:" /etc/passwd | cut -d: -f5)
    nom=$(echo "$full_name" | awk '{print $1}')
    prenom=$(echo "$full_name" | awk '{print $2}')

    echo "Nom : $nom"
    echo "Prénom : $prenom"
    echo "Login : $i"
    echo "Groupe primaire : ${group_array[0]}"
    echo "Groupes secondaires : ${group_array[@]:1}"
    echo "Taille du répertoire personnel : $(du -sb /home/$i | cut -f1)"

    if sudo -l -U "$i" | grep -q "(ALL) ALL"; 
    then
        echo "Sudoer : Oui"
    else
        echo "Sudoer : Non"
    fi
    echo "--------------------"
done


if ! $results; 
then
    echo "Aucun résultat"
fi
