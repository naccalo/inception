
NAME = inception
DATA_PATH = /home/lesb/data

COMPOSE = docker compose -p $(NAME) -f ./srcs/docker-compose.yml

make: all

setup:
	sudo mkdir -p $(DATA_PATH)/mariadb
	sudo mkdir -p $(DATA_PATH)/wordpress

all: setup build upd

build:
	$(COMPOSE) build
up:
	$(COMPOSE) up
upd:
	$(COMPOSE) up -d
down:
	$(COMPOSE) down
downv:
	$(COMPOSE) down -v
ps:
	$(COMPOSE) ps
psa:
	$(COMPOSE) ps -a
start:
	$(COMPOSE) start
stop:
	$(COMPOSE) stop
restart:
	$(COMPOSE) restart

volumes:
	@docker volume ls | grep $(NAME)

volumes-prune:
	docker volume prune -f

networks:
	@docker network ls | grep $(NAME)

networks-prune:
	docker network prune -f

prune:
	docker system prune -af

fclean: downv
	sudo rm -rf $(DATA_PATH)/mariadb
	sudo rm -rf $(DATA_PATH)/wordpress
	docker system prune -af

re: fclean all

.PHONY: all build up upd down downv ps psa start stop restart volumes volumes-prune networks networks-prune prune fclean re

