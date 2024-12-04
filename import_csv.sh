#!/usr/bin/bash

# Définir la variable de mot de passe MySQL (évite de le laisser en clair dans la commande)
MYSQL_PASS='dolibarr'

# Fichier CSV à traiter
CSV_FILE="export_societe.csv"

# Vérification que le fichier CSV existe
if [ ! -f "$CSV_FILE" ]; then
    echo "Le fichier CSV '$CSV_FILE' est introuvable !"
    exit 1
fi

# Lecture du CSV à partir de la 2ème ligne (ignorer l'entête)
tail -n +2 "$CSV_FILE" | while IFS="," read -r nom name_alias; do
    # Vérifier si les champs sont non vides
    if [ -z "$nom" ] || [ -z "$name_alias" ]; then
        echo "Erreur : une ligne du fichier CSV contient des champs vides. Ignorer cette ligne."
        continue
    fi

    # Échapper les valeurs pour éviter les problèmes d'injection SQL
    nom=$(echo "$nom" | sed "s/'/''/g")
    name_alias=$(echo "$name_alias" | sed "s/'/''/g")

    # Requête SQL d'insertion
    query="INSERT INTO llx_societe (nom, name_alias) VALUES ('$nom', '$name_alias');"

    # Exécution de la requête via la commande mysql
    if ! mysql -u dolibarr -p"$MYSQL_PASS" -h 127.0.0.1 --port=3306 dolibarr -e "$query"; then
        echo "Erreur lors de l'exécution de la requête pour $nom ($name_alias)"
    else
        echo "Insertion réussie : $nom ($name_alias)"
    fi
done

