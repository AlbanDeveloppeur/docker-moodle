ifndef VERBOSE
.SILENT:
endif

#---VARIABLES---------------------------------#

#---DOCKER---#
DOCKER = sudo docker

DOCKER_COMPOSE = $(DOCKER) compose
DOCKER_COMPOSE_UP = $(DOCKER_COMPOSE) up -d
DOCKER_COMPOSE_STOP = $(DOCKER_COMPOSE) stop
DOCKER_COMPOSE_DOWN = $(DOCKER_COMPOSE) down

DOCKER_IMAGE = $(DOCKER) image
DOCKER_IMAGE_RM = $(DOCKER_IMAGE) rm

DOCKER_RUN = $(DOCKER_COMPOSE) run
DOCKER_EXEC = $(DOCKER) exec
#------------#

#---MOODLE---#
MOODLE_TMP_DIR = /tmp
MOODLE_WGET_URL = https://download.moodle.org/download.php/direct/stable$(MOODLE_VERSION)/$(MOODLE_TGZ_NAME)
MOODLE_TGZ_NAME = moodle-latest-$(MOODLE_VERSION).tgz
MOODLE_WGET = wget -P $(MOODLE_TMP_DIR) $(MOODLE_WGET_URL)
MOODLE_TMP_FOLDER = moodle
#------------#

#---LINUX---#
USER := $(shell whoami)
#-----------#

##=== 🆘  HELP ==================================================
help: ## Show this help.
	@echo "Moodle-And-Docker-Makefile"
	@echo "---------------------------"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
#---------------------------------------------#

##=== 🐳  DOCKER ================================
.PHONY: docker-down
docker-down: ## Delete docker containers
	$(DOCKER_COMPOSE_DOWN)

.PHONY: docker-bash
docker-bash: ## Open container bash | need "container" variable
	$(DOCKER_COMPOSE_UP) $(container)
	$(DOCKER_EXEC) -it $(container) /bin/bash

##=== Ⓜ️  MOODLE ===============================
.PHONY: moodle-install
moodle-install: ## Install Moodle | need "MOODLE_VERSION" variable
	$(DOCKER_COMPOSE_STOP)

	sudo apt update
	sudo apt install tar

	sudo rm -rdf ./moodle_data
	sudo mkdir ./moodle_data

	$(MOODLE_WGET)

	sudo tar -xvzf $(MOODLE_TMP_DIR)/$(MOODLE_TGZ_NAME) -C $(MOODLE_TMP_DIR)
	sudo mv $(MOODLE_TMP_DIR)/$(MOODLE_TMP_FOLDER)/* ./moodle_data
	sudo rm -rdf $(MOODLE_TMP_DIR)/$(MOODLE_TMP_FOLDER) $(MOODLE_TMP_DIR)/$(MOODLE_TGZ_NAME)

	sleep 5

	$(DOCKER_COMPOSE_UP)

	sleep 5

	$(DOCKER_RUN) --rm moodle bash -c "chown www-data /var/www/html"
	$(DOCKER_RUN) --rm moodle sh -c "sh /var/www/assets/scripts/install_moodle.sh"

	sudo chmod -R 777 ./
	sudo chown -R $(USER):$(USER) ./

	$(info [OK] Moodle is running on localhost:8080)

.PHONY: moodle-start
moodle-start: ## Start Moodle containers.
	$(DOCKER_COMPOSE_UP)

.PHONY: moodle-stop
moodle-stop: ## Stop Moodle containers
	$(DOCKER_COMPOSE_STOP)

.PHONY: moodle-down
moodle-down: ## Uninstall moodle containers and folders
	$(DOCKER_COMPOSE_DOWN)
	sudo rm -rdf moodle_data/

.PHONY: moodle-purge-caches
moodle-purge-caches: ## Purging all caches from Moodle app
	$(DOCKER_EXEC) -it moodle /bin/bash -c "php admin/cli/purge_caches.php"
