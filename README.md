# Docker Moodle

Commande `make` pour afficher les possibilités

```
=== 🆘  HELP ==================================
help                           Show this help.
=== 🐳  DOCKER ================================
docker-down                    Delete docker containers
docker-bash                    Open container bash | need "CONTAINER" variable
=== 📖  MOODLE ===============================
moodle-install                 Install Moodle | need "MOODLE_VERSION" variable
moodle-start                   Start Moodle containers.
moodle-stop                    Stop Moodle containers
moodle-down                    Uninstall moodle containers and folders
moodle-purge-caches            Purging all caches from Moodle app
```

## Installer Moodle
Lancez la commande :
```
make moodle-install MOODLE_VERSION=XXX
```

`XXX` correspond à la version de Moodle. Voici quelques exemples de version possible :
- 405 : Moodle 4.5
- 502 : Moodle 5.2

Une fois l'installation terminé, accédez à l'url `localhost:8080` pour ouvrir l'application Moodle.

> [!NOTE]
> Les identifiants par défaut\
>\
> **Identifiant** : admin\
> **Mot de passe** : !Azerty12345

## Désinstaller Moodle et les containers
Lancez la commande :
```
make moodle-down
```