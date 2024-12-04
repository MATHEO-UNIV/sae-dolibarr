#!/bin/bash

# Nettoyage des volumes et des conteneurs existants
docker rm -f mysql-cont dolibarr-cont
docker volume rm dolibarr_db dolibarr_html dolibarr_docs

#ETAPE 1 : création des volumes nécessaires
docker volume create dolibarr_db
docker volume create dolibarr_html
docker volume create dolibarr_docs

docker network create sae51

#ETAPE 2 : création du conteneur SGBD MySQL
docker run \
  --name mysql-cont \
  -p 3306:3306 \
  -v dolibarr_db:/var/lib/mysql \
  --env MYSQL_ROOT_PASSWORD=root \
  --env MYSQL_USER=dolibarr \
  --env MYSQL_PASSWORD=dolibarr \
  --env MYSQL_DATABASE=dolibarr \
  --env character_set_client=utf8 \
  --env character-set-server=utf8mb4 \
  --env collation-server=utf8mb4_unicode_ci \
  --network=sae51 \
  -d mysql:latest

# Vérification que MySQL est bien disponible
until mysql -u dolibarr -p'dolibarr' -h 127.0.0.1 --port=3306 -e "SELECT 1" &>/dev/null; do
  echo "Waiting for MySQL to be available..."
  sleep 2
done

#ETAPE 4 : Création du conteneur Dolibarr
docker run \
  -p 80:80 \
  --name dolibarr-cont \
  --env DOLI_DB_HOST=mysql-cont \
  --env DOLI_DB_NAME=dolibarr \
  --env DOLI_MODULES=modSociete \
  --env DOLI_ADMIN_LOGIN=admin \
  --env DOLI_ADMIN_PASSWORD=admin \
  --network=sae51 \
  -d upshift/dolibarr

# Attente avant lancement de l'interface Dolibarr
echo "Waiting for Dolibarr to start..."
sleep 10
