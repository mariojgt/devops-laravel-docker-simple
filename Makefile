.PHONY: network remove-network list-network start stop destroy volume build list link exe composer bun bun-upgrade bun-update

COMPOSE =sudo docker-compose
DOCKER = sudo docker
# Load .env file
DOCKER_PREFIX:= $(shell grep -E '^DOCKER_PREFIX' .env | cut -d '=' -f 2)
NETWORK_NAME:= $(shell grep -E '^NETWORK_NAME' .env | cut -d '=' -f 2)
CONTAINER_NAME:= $(shell grep -E '^CONTAINER_NAME' .env | cut -d '=' -f 2)
CODE_PATH:= $(shell grep -E '^CODE_PATH' .env | cut -d '=' -f 2)

REDIS_PORT:= $(shell grep -E '^REDIS_PORT' .env | cut -d '=' -f 2)
PHPMYADMIN_PORT:= $(shell grep -E '^PHPMYADMIN_PORT' .env | cut -d '=' -f 2)
MYAPP_PORT:= $(shell grep -E '^MYAPP_PORT' .env | cut -d '=' -f 2)
REDIS_INSIGHT_PORT:= $(shell grep -E '^REDIS_INSIGHT_PORT' .env | cut -d '=' -f 2)

# /*
# |--------------------------------------------------------------------------
# | network cmds
# |--------------------------------------------------------------------------
# */
network:
	@$(DOCKER) network create $(NETWORK_NAME)

remove-network:
	@$(DOCKER) network rm $(NETWORK_NAME)

list-network:
	@$(DOCKER) network ls

# /*
# |--------------------------------------------------------------------------
# | docker cmds
# |--------------------------------------------------------------------------
# */
start:
	@$(COMPOSE) up -d

stop:
	@$(COMPOSE) down

destroy:
	@$(COMPOSE) rm -v -s -f

volume:
	@$(DOCKER) volume ls

build:
	@$(COMPOSE) build

list:
	@$(COMPOSE) ps -a

prune:
	@$(DOCKER) system prune -a

host:
	$(COMPOSE) -f docker compose-ngrok.yml up -d

host-stop:
	$(COMPOSE) -f docker compose-ngrok.yml down

clear-redis:
	$(DOCKER) exec -it ${DOCKER_PREFIX}_${CONTAINER_NAME}_redis redis-cli flushall
# /*
# |--------------------------------------------------------------------------
# | Utility cmds
# |--------------------------------------------------------------------------
# */
link:
	@echo "Creating URLs for services with '$(DOCKER_PREFIX)_' prefix..."
	@SERVER_IP=$$(hostname -I | cut -d' ' -f1); \
	echo "http://$$SERVER_IP:$(PHPMYADMIN_PORT)"; \
	echo "http://$$SERVER_IP:$(REDIS_INSIGHT_PORT)"; \
	echo "http://$$SERVER_IP:$(MYAPP_PORT)"


exe:
	@$(DOCKER) exec -itu devuser ${DOCKER_PREFIX}_${CONTAINER_NAME}_app /bin/bash

# New command to run tests with code coverage
coverage: ## Run PHPUnit tests with code coverage
	@$(DOCKER) exec -itu devuser ${DOCKER_PREFIX}_${CONTAINER_NAME}_app \
		vendor/bin/phpunit --coverage-html=coverage/

# New command to run tests with text-based coverage report
coverage-text: ## Run PHPUnit tests with text-based coverage report
	@$(DOCKER) exec -itu devuser ${DOCKER_PREFIX}_${CONTAINER_NAME}_app \
		vendor/bin/phpunit --coverage-text

horizon:
	@$(DOCKER) exec -itu devuser ${DOCKER_PREFIX}_${CONTAINER_NAME}_app /bin/bash -c 'php artisan horizon'

composer:
	@$(DOCKER) exec -itu devuser ${DOCKER_PREFIX}_${CONTAINER_NAME}_app /bin/bash -c 'composer update && chmod -R 755 . && chmod -R 777 storage bootstrap/cache resources'

bun:
	@$(DOCKER) exec -itu devuser ${DOCKER_PREFIX}_${CONTAINER_NAME}_app /bin/bash -c 'bun install && bun run dev'

bun-upgrade:
	@$(DOCKER) exec -itu devuser ${DOCKER_PREFIX}_${CONTAINER_NAME}_app /bin/bash -c 'bun upgrade'

bun-update:
	@$(DOCKER) exec -itu devuser ${DOCKER_PREFIX}_${CONTAINER_NAME}_app /bin/bash -c 'bun update'

permission:
	@$(eval CURRENT_USER := $(shell whoami))
	@sudo chown -R $(CURRENT_USER):$(CURRENT_USER) *

# /*
# |--------------------------------------------------------------------------
# | Supervisor
# |--------------------------------------------------------------------------
# */

# Show processes running in container
ps:
	docker exec -it ${DOCKER_PREFIX}_${CONTAINER_NAME}_app ps aux

# Show supervisor status
status-supervisor:
	docker exec -it ${DOCKER_PREFIX}_${CONTAINER_NAME}_app supervisorctl status

# Stop all supervisor processes
stop-supervisor:
	docker exec -it ${DOCKER_PREFIX}_${CONTAINER_NAME}_app supervisorctl stop all

# Start all supervisor processes
start-supervisor:
	docker exec -it ${DOCKER_PREFIX}_${CONTAINER_NAME}_app supervisorctl start all

# Restart all supervisor processes
restart-supervisor:
	docker exec -it ${DOCKER_PREFIX}_${CONTAINER_NAME}_app supervisorctl restart all


# /*
# |--------------------------------------------------------------------------
# | SYNC FOLDERS THE PACKAGES
# |--------------------------------------------------------------------------
# */
USER := $(shell whoami)
PROJECTS_DIR := /home/$(USER)/projects/laravel-projects
CURRENT_DIR := $(shell basename $(CURDIR))

link-folder:
	ln -s $(PROJECTS_DIR)/repo $(PROJECTS_DIR)/projects/$(CURRENT_DIR)/project/$(CODE_PATH)/repo

install-laravel:
	cd project && composer create-project laravel/laravel $(CODE_PATH)

# case we need to reset laravel permissions
# sudo chown -R $(id -u):$(id -g) ./project/storage ./project/bootstrap/cache
# sudo chmod -R 775 ./project/storage ./project/bootstrap/cache

create-user:
	@$(DOCKER) exec -it ${DOCKER_PREFIX}_${CONTAINER_NAME}_app /bin/bash -c "adduser --disabled-password --gecos '' --uid $(USER_ID) --gid $(GROUP_ID) devuser"
	@$(DOCKER) exec -it ${DOCKER_PREFIX}_${CONTAINER_NAME}_app /bin/bash -c "chown -R devuser:devuser /var/www/html"
