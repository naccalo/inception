NAME = inception

COMPOSE = docker compose -f ./srcs/docker-compose.yml

all: build up

build:
	$(COMPOSE) build
up:
	$(COMPOSE) up
upd:
	$(COMPOSE) up -d
down:
	$(COMPOSE) down
downv:
	$(COMPOSE) down
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

prune-all: down prune volumes-prune networks-prune

.PHONY: all up upd down downv ps psa start stop restart volumes volumes-prune networks prune prune-all
