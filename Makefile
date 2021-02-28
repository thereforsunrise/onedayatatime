docker_web_name := onedayweb

ifeq ($(env), prod)
	docker_compose_file :=  docker-compose-prod.yml
else
	docker_compose_file :=  docker-compose.yml
endif

docker_sh := docker exec --user $(shell id -u):$(shell id -g) -w /home/app -it $(docker_web_name) /bin/bash
docker_sh_c := $(docker_sh) -c

.DEFAULT_GOAL := downup

FORCE:

down: FORCE
	@docker-compose -f $(docker_compose_file) down --remove-orphans

build: FORCE
	@docker-compose -f $(docker_compose_file) build

up: build
	@docker-compose -f $(docker_compose_file) up -d

restartweb: FORCE
	@docker-compose -f $(docker_compose_file) restart $(docker_web_name)

ifeq ($(env), prod)
downup: down up dbmigrate
else
downup: down up dbmigrate dbseed
endif

shell: FORCE
	@$(docker_sh)

logs: FORCE
	@docker-compose -f $(docker_compose_file) logs -f $(docker_web_name)

install: FORCE
	@$(docker_sh_c) 'bundle install'

dbshell: FORCE
	@$(docker_sh_c) 'mysql -u$$DB_USER -p$$DB_PASS -h$$DB_HOST $$DB_DB'

dbclean: FORCE
	@$(docker_sh_c) 'bundle exec rake db:drop; bundle exec rake db:create'

dbmigrate: FORCE
	@$(docker_sh_c) 'bundle exec rake db:migrate'

dbseed: FORCE
	@$(docker_sh_c) 'bundle exec rake db:seed'

dbsetup: dbclean dbmigrate dbseed
