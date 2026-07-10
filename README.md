# Docker Moodle

Commande `make` pour afficher les possibilités

```
Moodle-And-Docker-Makefile
---------------------------
Usage: make [target]

Targets:
=== 🆘  HELP ==================================================
help                           Show this help.
=== 🐳  DOCKER ================================
docker-up                      Start docker containers.
docker-stop                    Stop docker containers
docker-down                    Delete docker containers
docker-bash                    Open container bash | need $container variable
=== Ⓜ️  MOODLE ===============================
moodle-install                 Install Moodle
moodle-down                    Uninstall moodle containers and folders
moodle-purge-caches            Purging all caches from Moodle app
```

## Installer Moodle
Aller sur le site : [Github Moodle](https://github.com/moodle/moodle/tree/main) et télécharger la version de Moodle souhaité.

De préférence, choisissez une version `MOODLE_XX_STABLE`;

Dans le dossier 'assets/moodle/version' ajouter le zip du Moodle à installer.

Dans le fichier Makefile, changer la valeur de la variable MOODLE_FOLDER_NAME du nom du fichier ZIP importé.
Par exemple : `moodle-MOODLE_405_STABLE`. Ne mettez pas le '.zip'

Puis lancer la commande :
```
make moodle-install
```

Puis accéder à l'url `localhost:8080` (ou suivant le port configurer dans le docker-compose) pour accéder à Moodle.

## Désinstaller l'application
```
make moodle-down
```