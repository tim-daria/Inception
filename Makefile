COMPOSE_FILE = srcs/docker-compose.yml
export DATA_DIR ?= $(HOME)/data
.PHONY: all start stop down fclean re

all: start

start: build
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	@docker compose -f "$(COMPOSE_FILE)" up -d

build:
	@docker compose -f "$(COMPOSE_FILE)" build

stop:
	@docker compose -f "$(COMPOSE_FILE)" stop

down:
	@docker compose -f "$(COMPOSE_FILE)" down

fclean:
	@docker compose -f "$(COMPOSE_FILE)" down -v --remove-orphans
	rm -rf $(DATA_DIR) 2>/dev/null || sudo rm -rf $(DATA_DIR)
	docker rmi mariadb:1.0 wordpress:1.0 nginx:1.0 2> /dev/null || true
	@docker image prune -f

re: fclean start
