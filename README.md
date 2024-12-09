# SAE52 : Installation d'un ERP/CRM

## Objectif du projet

Nous avons pour objectif d'installer, configurer et automatiser l'installation d'un ERP/CRM **Dolibarr** sur un serveur dédié hébergé en interne. Le projet inclut également l'importation des données depuis une ancienne solution externalisée sous forme de fichiers CSV. À terme, nous devrons fournir une solution clé en main permettant de gérer les informations relatives aux clients et fournisseurs, avec un processus d'importation des données et une gestion de la sauvegarde.

## Sommaire

1. [Prérequis](#prérequis)
2. [Installation de Dolibarr](#installation-de-dolibarr)
3. [Importation des données](#importation-des-données)
4. [Dockerisation](#dockerisation)
5. [Sauvegarde des données](#sauvegarde-des-données)
6. [Structure du projet](#structure-du-projet)
7. [Suivi du projet](#suivi-du-projet)
8. [Références](#références)

---

## Prérequis

Avant de commencer l'installation de Dolibarr, nous devons nous assurer que notre environnement répond aux exigences suivantes :

- **Système d'exploitation** : Debian/Ubuntu ou tout autre environnement compatible Docker.
- **Docker** : Nous devons avoir Docker et Docker Compose installés sur notre machine.
- **Accès root ou sudo** : Nous aurons besoin des privilèges d'administrateur pour installer les paquets nécessaires et configurer le système.
  
  Nous pouvons installer Docker sur Debian/Ubuntu en suivant ces étapes :

  ```bash
  sudo apt-get update
  sudo apt-get install -y docker.io docker-compose
  ```

---

## Installation de Dolibarr

**Dolibarr** est un logiciel gratuit qui aide les petites et moyennes entreprises à gérer leurs activités. Il combine deux fonctions principales : la gestion de l'entreprise (ERP) et la gestion des relations avec les clients (CRM). Avec **Dolibarr**, on peut facilement gérer les clients, les fournisseurs, les stocks, les factures, les paiements, ainsi que les projets.

Ce logiciel est modulaire, ce qui signifie que l'on peut choisir d'activer ou de désactiver certaines fonctionnalités en fonction des besoins de l'entreprise. Il possède une interface web simple, accessible depuis n'importe quel appareil, ce qui permet de l'utiliser à distance.

**Dolibarr** est écrit en PHP et peut fonctionner avec des bases de données comme MySQL ou MariaDB. Il existe plusieurs façons de l'installer : en téléchargeant les fichiers source, en utilisant des paquets Debian, ou en utilisant des images Docker pour une installation plus rapide et facile.

---

### Étape 1 : Installation manuelle sur une machine virtuelle ou un conteneur Docker

1. **Téléchargement de la version Dolibarr** :
   - Nous pouvons télécharger la version `.deb` ou la version source de Dolibarr depuis le [site officiel](https://www.dolibarr.org).
   - Si nous utilisons la version source, nous devrons installer les dépendances nécessaires telles que PHP, Apache/Nginx et un serveur de base de données (MySQL, MariaDB, ou PostgreSQL).

2. **Installation sur Debian/Ubuntu avec un paquet `.deb`** :

   Si nous optons pour la version Debian, nous pouvons installer Dolibarr en utilisant le gestionnaire de paquets `dpkg` :

   ```bash
   sudo dpkg -i dolibarr.deb
   sudo apt-get install -f  # Pour résoudre les dépendances manquantes
   ```

---

## Importation des données

### Étape 2 : Importation des données CSV

L'importation des données depuis un ancien système ERP/CRM sera réalisée à partir des fichiers CSV fournis. 

1. **Méthode 1 : Utilisation des outils intégrés de Dolibarr** :
   - Dolibarr propose un menu d'importation de fichiers CSV. Cette méthode est simple mais non automatisable.

2. **Méthode 2 : Importation directe dans la base de données** :
   - Cette méthode consiste à analyser les tables Dolibarr et à écrire un script SQL ou un script Python pour importer les données directement dans la base de données.
   - Exemple de script SQL pour importer un fichier CSV dans la table `llx_societe` de Dolibarr :
   
   ```sql
   LOAD DATA INFILE '/path/to/clients.csv'
   INTO TABLE llx_societe
   FIELDS TERMINATED BY ','
   ENCLOSED BY '"'
   LINES TERMINATED BY '\n'
   (name, address, phone, email);
   ```

---

## Dockerisation

### Étape 3 : Préparation de l'environnement

Pour déployer Dolibarr dans un environnement de production, nous allons utiliser Docker pour containeriser l'application et la base de données.

1. **install.sh** :
   Nous allons utiliser un **install.sh** pour orchestrer les conteneurs pour Dolibarr et la base de données. Voici l'apercu de notre **install.sh** :

   ``` #!/bin/bash

   sudo systemctl stop mysql
   sudo systemctl stop apache2

   # Nettoyage des volumes et des conteneurs existants
   docker rm -f mysql-cont dolibarr-cont
   docker volume rm dolibarr_db dolibarr_html dolibarr_docs

   #ETAPE 1 : création des volumes nécessaires
   docker volume create dolibarr_db
   docker volume create dolibarr_html
   docker volume create dolibarr_docs

   docker network rm sae51
   docker network create sae51

   #ETAPE 2 : création du conteneur SGBD MySQL
   docker rm -f mysql-cont dolibarr-cont
   docker network rm sae51
   docker network create sae51

   docker run \
   --name mysql-cont \
   -p 3306:3306 \
   -v dolibarr_db:/var/lib/mysql \
   --env MYSQL_ROOT_PASSWORD=root \
   --env MYSQL_USER=dolibarr \
   --env MYSQL_PASSWORD=dolibarr \
   --env MYSQL_DATABASE=dolibarr \
   --network=sae51 \
   -d mysql:latest

   sleep 15

   #ETAPE 4 : Création du conteneur Dolibarr
   docker run \
   -p 80:80 \
   --name dolibarr-cont \
   --env DOLI_DB_HOST=mysql-cont \
   --env DOLI_DB_NAME=dolibarr \
   --env DOLI_ADMIN_LOGIN=admin \
   --env DOLI_ADMIN_PASSWORD=admin \
   --network=sae51 \
   -d upshift/dolibarr

   # Attente avant lancement de l'interface Dolibarr
   echo "Waiting for Dolibarr to start..."
   sleep 10
   ```

---

## Sauvegarde des données

### Étape 4 : Sauvegarde et récupération des données

Pour assurer la disponibilité des données et permettre une récupération rapide en cas de défaillance (Plan de Reprise d'Activité - PRA), il est crucial de mettre en place une solution de sauvegarde.

1. **Sauvegarde de la base de données** :
   Nous pouvons utiliser des outils comme `mysqldump` pour créer une sauvegarde de la base de données :

   ```bash
   mysqldump -u root -p dolibarr > backup_dolibarr.sql
   ```

2. **Sauvegarde des fichiers Dolibarr** :
   Les fichiers de configuration et les fichiers générés par Dolibarr doivent également être sauvegardés. Nous pouvons utiliser `rsync` pour sauvegarder les répertoires importants.

---

## Structure du projet

Voici la structure de répertoires que nous avons choisie pour ce projet :

```
sae-dolibarr/
│
├── sources/             # Scripts source, Dockerfile, etc.
├── tests/               # Scripts de tests, essais
├── data/                # Fichiers de données (CSV, etc.)
├── sources.md           # Références aux sources utilisées
├── readme.md            # Ce fichier README
├── suivi_projet.md      # Suivi du projet
```

---

## Suivi du projet

Nous étions chargé de mettre à jour le fichier `suivi_projet.md` après chaque séance pour montrer l'avancement du projet, les obstacles rencontrés et les actions à venir. Il est très utile en début de séances pour tout simplement reprendre le projet la ou nous l'avions arreté.

---

## Références

- [Site officiel de Dolibarr](https://www.dolibarr.org/)
- [Docker pour Dolibarr](https://hub.docker.com/r/dolibarr/dolibarr)
- [Installation de Dolibarr sur Debian](https://all-it-network.com/installer-dolibar/)
- [Documentation Docker](https://docs.docker.com/)

---

## Conclusion

Une fois la date du projet terminée, nous avons pas eu le temps de tout effectuer, nous avons rencontré des difficultés comme par exemple notre Dolibarr qui se ferme quelques secondes après avoir éxécuter notre install.sh.

## Membres du projet

1. Fourneaux Mathéo  
2. Francoise Paul 

---

