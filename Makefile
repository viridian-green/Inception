COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/ademarti/data

.PHONY: all build up down clean fclean re

all: build up

# Create data directories
$(DATA_DIR)/mariadb:
	@mkdir -p $(DATA_DIR)/mariadb

$(DATA_DIR)/wordpress:
	@mkdir -p $(DATA_DIR)/wordpress

# Build images
build: $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	docker compose -f $(COMPOSE_FILE) build

# Start services
up:
	@echo "Checking if port 443 is free..."
	@PORT_PID=$$(sudo lsof -t -i :443); \
	if [ ! -z "$$PORT_PID" ]; then \
		echo "Port 443 is in use by PID $$PORT_PID, killing process..."; \
		sudo kill -9 $$PORT_PID; \
	else \
		echo "Port 443 is free."; \
	fi
	docker compose -f $(COMPOSE_FILE) up -d

# Stop services
down:
	docker compose -f $(COMPOSE_FILE) down

# Clean containers and images
clean:
	docker compose -f $(COMPOSE_FILE) down
	docker system prune -af

# Full clean including volumes
fclean: clean
	sudo rm -rf $(DATA_DIR)

# Rebuild everything
re: clean all
