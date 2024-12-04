#!/usr/bin/bash

tail -n +2 "./export_societe.csv" | while IFS="," read -r nom name_alias;
do
    # Requête SQL d'insertion pour chaque ligne du CSV
    query="INSERT INTO llx_societe (nom, name_alias) VALUES ('$nom', '$name_alias');"

    # Exécution de la requête via la commande mysql
    mysql -u dolibarr -p'dolibarr' -h 127.0.0.1 --port=3306 dolibarr -e "$query"
    
done
