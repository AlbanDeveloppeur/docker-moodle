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
```

## Installer Moodle
Dans le dossier 'assets/moodle/version' ajouter le zip du Moodle à installer.
Le nommage du fichier .zip doit être "moodle-X.X.X.zip".

Dans le fichier Makefile, changer la version de la variable MOODLE_VERSION.

Puis lancer la commande :

```
make moodle-install
```

## Désinstaller Moodle

```
make moodle-down
```