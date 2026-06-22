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
docker-up: ## Start docker containers.
	$(DOCKER_COMPOSE_UP)
.PHONY: docker-up

docker-stop: ## Stop docker containers
	$(DOCKER_COMPOSE_STOP)
.PHONY: docker-stop

docker-down: ## Delete docker containers
	$(DOCKER_COMPOSE_DOWN)
.PHONY: docker-down

docker-bash: ## Open container bash | need $container variable
	$(DOCKER_COMPOSE_UP) $(container)
	$(DOCKER_EXEC) -it $(container) /bin/bash
.PHONY: docker-bash

##=== Ⓜ️  MOODLE ===============================

moodle-install: ## Install Moodle
	$(DOCKER_COMPOSE_STOP)

	sudo apt update
	sudo apt install unzip

	sudo rm -rdf ./moodle_data
	sudo mkdir ./moodle_data

	sudo unzip ./assets/moodle/version/5.2.1/moodle-5.2.1.zip -d /tmp
	sudo mv /tmp/moodle/* ./moodle_data
	sudo rm -rdf /tmp/moodle

	sleep 5

	$(DOCKER_COMPOSE_UP)

	sleep 5

	$(DOCKER_RUN) --rm moodle bash -c "chown www-data /var/www/html"
	$(DOCKER_RUN) --rm moodle sh -c "sh /var/www/assets/scripts/install_moodle.sh"

	sudo chmod -R 777 ./
	sudo chown -R $(USER):$(USER) ./
.PHONY: moodle-install

moodle-down: ## Uninstall moodle containers and folders
	$(DOCKER_COMPOSE_DOWN)
	sudo rm -rdf moodle_data/
.PHONY: moodle-down
