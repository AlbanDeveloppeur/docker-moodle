SHELL := /bin/bash

.DEFAULT_GOAL := help

ifndef VERBOSE
.SILENT:
endif

#---VARIABLES---------------------------------#

#---DOCKER---#
DOCKER = docker

DOCKER_COMPOSE = $(DOCKER) compose
DOCKER_COMPOSE_UP = $(DOCKER_COMPOSE) up -d
DOCKER_COMPOSE_STOP = $(DOCKER_COMPOSE) stop
DOCKER_COMPOSE_DOWN = $(DOCKER_COMPOSE) down
DOCKER_COMPOSE_RUN = $(DOCKER_COMPOSE) run

DOCKER_EXEC = $(DOCKER) exec

CONTAINER_TIMEOUT ?= 30
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

#---COLORS---#
# Texte
BLACK  := \033[30m
RED    := \033[31m
GREEN  := \033[32m
YELLOW := \033[33m
RESET  := \033[0m

# Fond
BG_RED    := \033[41m
BG_GREEN  := \033[42m

# Font param
BOLD		:= \033[1m
UNDERLINE	:= \033[4m

#------------#

#---------------------------------------------#


#---FONCTIONS---------------------------------#

define check-var
	if [ -z "$($(1))" ]; then \
		printf "$(RED)❌ The \"$(1)\" variable is required.$(RESET)\n"; \
		printf "   $(2)\n"; \
		exit 1; \
	fi
endef

#---------------------------------------------#


#---COMMANDES---------------------------------#

check-docker-perms:
	docker info >/dev/null 2>&1 || { \
		printf "❌ $(BG_RED)Unable to access Docker.$(RESET) Add your user to the docker group:\n"; \
		printf "   sudo usermod -aG docker \$$USER && newgrp docker\n"; \
		exit 1; \
	}
.PHONY: check-docker-perms

check-deps:
	command -v tar >/dev/null 2>&1 || { printf "❌ $(BG_RED)'tar' is required.$(RESET) Install it: sudo apt install tar\n"; exit 1; }
	command -v docker >/dev/null 2>&1 || { printf "❌ $(BG_RED)Docker is required.$(RESET)\n"; exit 1; }
.PHONY: check-deps

moodle-verify:
	file $(MOODLE_TMP_DIR)/$(MOODLE_TGZ_NAME) | grep -q "gzip compressed" || \
		{ printf "❌ $(BG_RED)The downloaded file is not a valid archive.$(RESET)\n"; exit 1; }
.PHONY: moodle-verify

wait-for-container:
	$(call check-var,CONTAINER,Usage: make wait-for-container CONTAINER=moodle)

	if ! $(DOCKER) inspect -f '{{.State.Running}}' $(CONTAINER) 2>/dev/null | grep -q true; then \
		printf "❌ $(RED)The container \"$(CONTAINER)\" has not started or does not exist.$(RESET)\n"; \
		printf "   Check using: docker compose ps\n"; \
		exit 1; \
	fi
	timeout=$(CONTAINER_TIMEOUT); elapsed=0; \
	while [ "$$($(DOCKER) inspect -f '{{.State.Health.Status}}' $(CONTAINER) 2>/dev/null)" != "healthy" ]; do \
		if ! $(DOCKER) inspect -f '{{.State.Health.Status}}' $(CONTAINER) >/dev/null 2>&1; then \
			printf "⚠️ $(YELLOW)No healthcheck defined for \"$(CONTAINER)\", simple status check.$(RESET)\n"; \
			break; \
		fi; \
		if [ $$elapsed -ge $$timeout ]; then \
			printf "❌ $(RED)Timeout : \"$(CONTAINER)\" has not become \"healthy\" after $${timeout} sec.$(RESET)\n"; \
			printf "   Check the logs using: docker-compose logs $(CONTAINER)\n"; \
			exit 1; \
		fi; \
		sleep 1; elapsed=$$((elapsed + 1)); \
	done;
.PHONY: wait-for-container

wait-for-containers:
	containers=$$($(DOCKER_COMPOSE) ps --format '{{.Name}}'); \
	if [ -z "$$containers" ]; then \
		printf "⚠️ $(YELLOW)No containers found. Have you run \"docker compose up\" ?$(RESET)\n"; \
		exit 1; \
	fi; \
	for c in $$containers; do \
		$(MAKE) wait-for-container CONTAINER=$$c || exit 1; \
	done; \
	printf "✅ $(GREEN)All the containers are ready$(RESET)\n"
.PHONY: wait-for-containers

#---------------------------------------------#

##=== 🆘  HELP ==================================
help: ## Show this help.
	echo "Moodle-And-Docker-Makefile"
	echo "---------------------------"
	echo "Usage: make [target]"
	echo ""
	echo "Targets:"
	grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "$(GREEN)%-30s$(RESET) %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
.PHONY: help

##=== 🐳  DOCKER ================================
docker-down: check-docker-perms ## Delete docker containers
	printf "🗑️ Deleting containers\n"
	$(DOCKER_COMPOSE_DOWN)
	echo "✅ $(GREEN)The containers have been removed.$(RESET)"
.PHONY: docker-down

docker-bash: check-docker-perms ## Open container bash | need "CONTAINER" variable
	$(call check-var,CONTAINER,Usage: make docker-bash CONTAINER=moodle)

	echo "⏳ Starting the $(CONTAINER) container"
	$(DOCKER_COMPOSE_UP) $(CONTAINER)

	$(MAKE) wait-for-container CONTAINER=$(CONTAINER)

	echo "✅ $(GREEN)The container is ready.$(RESET)"

	$(DOCKER_EXEC) -it $(CONTAINER) /bin/bash
.PHONY: docker-bash

##=== 📖  MOODLE ===============================
moodle-install: check-deps check-docker-perms ## Install Moodle | need "MOODLE_VERSION" variable
	$(call check-var,MOODLE_VERSION,Usage: make moodle-install MOODLE_VERSION=502)

	$(DOCKER_COMPOSE_STOP)

	sudo rm -rdf ./moodle_data

	printf "(1/8) 📁 Creating the "moodle_data" directory\n"
	sudo mkdir ./moodle_data

	printf "(2/8) ⏳ Download Moodle version $(BOLD)$(MOODLE_VERSION)$(RESET)\n"
	$(MOODLE_WGET)

	printf "(3/8) 🚨 Verifying the downloaded file\n"
	$(MAKE) moodle-verify
	printf "(4/8) ✅ $(BOLD)Moodle $(MOODLE_VERSION)$(RESET) download completed\n"

	printf "(5/8) 📁 Settings up \"moodle_data\" files\n"
	sudo tar -xzf $(MOODLE_TMP_DIR)/$(MOODLE_TGZ_NAME) -C $(MOODLE_TMP_DIR)
	sudo mv $(MOODLE_TMP_DIR)/$(MOODLE_TMP_FOLDER)/* ./moodle_data
	sudo rm -rdf $(MOODLE_TMP_DIR)/$(MOODLE_TMP_FOLDER) $(MOODLE_TMP_DIR)/$(MOODLE_TGZ_NAME)

	printf "(6/8) 🐳 Setting up the Moodle and the database containers\n"
	$(DOCKER_COMPOSE_UP)

	$(MAKE) wait-for-containers

	printf "(7/8) ⏳ Installating Moodle\n"
	$(DOCKER_COMPOSE_RUN) --rm moodle bash -c "chown www-data /var/www/html"
	$(DOCKER_COMPOSE_RUN) --rm moodle sh -c "sh /var/www/assets/scripts/install_moodle.sh"

	printf "(8/8) 📁 Changes Moodle file permissions\n"
	sudo chown -R $(USER):$(USER) ./moodle_data
	sudo find ./moodle_data -type d -exec chmod 755 {} \;
	sudo find ./moodle_data -type f -exec chmod 644 {} \;

	printf "\n$(BG_GREEN)$(BLACK)[OK] The installation of Moodle is complete: $(UNDERLINE)http://localhost:8080$(RESET)\n"
.PHONY: moodle-install

moodle-start: check-docker-perms ## Start Moodle containers.
	$(DOCKER_COMPOSE_UP)

	$(MAKE) wait-for-containers
.PHONY: moodle-start

moodle-stop: check-docker-perms ## Stop Moodle containers
	$(DOCKER_COMPOSE_STOP)

	printf "✅ $(GREEN)Containers have been stopped.$(RESET)\n"
.PHONY: moodle-stop

moodle-down: check-docker-perms ## Uninstall moodle containers and folders
	read -p "⚠️ This will permanently delete moodle_data/. Continue ? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1

	printf "🗑️ $(BG_RED)Removing containers$(RESET)\n"
	$(DOCKER_COMPOSE_DOWN)
	printf "✅ $(GREEN)Containers have been deleted.$(RESET)\n"

	printf "🗑️ $(BG_RED)Removing $(BOLD)moodle_data$(RESET) directory\n"
	sudo rm -rf moodle_data/
	printf "✅ $(GREEN)moodle_data directory have been deleted.$(RESET)\n"
.PHONY: moodle-down

moodle-purge-caches: check-docker-perms ## Purging all caches from Moodle app
	$(MAKE) wait-for-container CONTAINER=moodle

	$(DOCKER_EXEC) -it moodle /bin/bash -c "php admin/cli/purge_caches.php"

	printf "✅ $(GREEN)Caches has been purge.$(RESET)\n"
.PHONY: moodle-purge-caches
