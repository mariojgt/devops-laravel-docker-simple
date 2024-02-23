.PHONY: start stop build composer list create-network remove-network

COMPOSE =sudo docker-compose
DOCKER = sudo docker
# Load .env file
NETWORK_NAME := $(shell grep -E '^NETWORK_NAME' .env | cut -d '=' -f 2)

network:
	@$(DOCKER) network create $(NETWORK_NAME)

remove-network:
	@$(DOCKER) network rm $(NETWORK_NAME)

list-network:
	@$(DOCKER) network ls

start:
	@$(COMPOSE) up -d

stop:
	@$(COMPOSE) down

build:
	@$(COMPOSE) build

list:
	@$(COMPOSE) ps -a

link:
	@echo "Creating IP address and port list for services with '$(DOCKER_PREFIX)_' prefix..."
	@SERVER_IP=$$(hostname -I | cut -d' ' -f1); \
	$(DOCKER) ps --format "{{.Names}}\t{{.Ports}}" | \
	awk -v serverip=$$SERVER_IP '/$(DOCKER_PREFIX)/ {split($$2, port, "[:>]"); print serverip":"port[2]}'

composer:
	@$(COMPOSE) exec $(APP) composer install
	@$(COMPOSE) exec $(APP) chmod -R 777 storage bootstrap/cache
