.DEFAULT_GOAL := help

SHELL := /usr/bin/env bash

project := visit_history

.PHONY: setup # Setup a working environment
setup:
	env PIPENV_VENV_IN_PROJECT=1 pipenv install --dev

.PHONY: shell # Spawn a shell within the virtual environment
shell:
	env PIPENV_DOTENV_LOCATION=.env.example pipenv shell

.PHONY: lint # Run linter
lint:
	pipenv run pylint ${project}/

.PHONY: prepare-test-containers
prepare-test-containers:
	@echo Starting db container...
	@docker run -d \
		--rm \
		--pull missing \
		--name ${project}_test_db \
		--tmpfs /data \
		-p 6380:6379 \
		redis:6-alpine

stop-prepared-test-containers := echo && \
	echo Stopping db container...; \
	docker stop ${project}_test_db

.PHONY: test # Run tests
test: prepare-test-containers
	@sleep 1
	@trap '${stop-prepared-test-containers}' EXIT && \
		echo Starting tests... && \
		env PIPENV_DOTENV_LOCATION=.env.example \
			pipenv run env REDIS_PORT=6380 \
			pytest --disable-warnings tests/

.PHONY: coverage # Run tests with coverage report
coverage: prepare-test-containers
	@sleep 1
	@trap '${stop-prepared-test-containers}' EXIT && \
		echo Starting tests... && \
		env PIPENV_DOTENV_LOCATION=.env.example \
			pipenv run env REDIS_PORT=6380 \
			pytest --disable-warnings \
				--cov-report term-missing:skip-covered \
				--cov=${project} \
				tests/

.PHONY: prepare-temp-containers
prepare-temp-containers:
	@echo Starting db container...
	@docker run -d \
		--rm \
		--pull always \
		--name ${project}_temp_db \
		-p 6379:6379 \
		redis:6-alpine

stop-prepared-temp-containers := echo && \
	echo Stopping db container...; \
	docker stop ${project}_temp_db

.PHONY: start # Start development Web server (with database)
start: prepare-temp-containers
	@sleep 1
	@trap '${stop-prepared-temp-containers}' EXIT && \
		echo Starting application... && \
		env PIPENV_DOTENV_LOCATION=.env.example \
			pipenv run uvicorn ${project}.main:app --reload

.PHONY: db # Start Redis container
db: prepare-temp-containers
	@trap '${stop-prepared-temp-containers}' EXIT && \
		echo Press CTRL+C to stop && \
		sleep 1d

.PHONY: app # Start application Web server (without database)
app:
	@echo Starting application...
	@env PIPENV_DOTENV_LOCATION=.env.example \
		pipenv run gunicorn --config ./gunicorn.conf.py ${project}.main:app

.PHONY: requirements # Generate requirements.txt file
requirements:
	pipenv lock --requirements > requirements.txt

.PHONY: up # Start Compose services
up:
	docker-compose pull redis nginx
	docker-compose build --pull
	docker-compose up

.PHONY: down # Stop Compose services
down:
	docker-compose down

.PHONY: up-dev # Start Compose services (development)
up-dev:
	docker-compose -f docker-compose.dev.yml pull redis
	docker-compose -f docker-compose.dev.yml build --pull
	docker-compose -f docker-compose.dev.yml up

.PHONY: down-dev # Stop Compose services (development)
down-dev:
	docker-compose -f docker-compose.dev.yml down

.PHONY: up-debug # Start Compose services (debug)
up-debug:
	docker-compose -f docker-compose.debug.yml pull redis
	docker-compose -f docker-compose.debug.yml build --pull
	docker-compose -f docker-compose.debug.yml up

.PHONY: down-debug # Stop Compose services (debug)
down-debug:
	docker-compose -f docker-compose.debug.yml down

.PHONY: prod-prepare-files
prod-prepare-files:
	@mkdir -p ENV
	@echo Copying files...
	@cp --verbose .env.example ENV/.env.app
	@cp --verbose .env.example ENV/.env.nginx
	@cp --verbose etc/service-example.conf etc/nginx/service-visit-history.conf
	@echo Do not forget to modify:
	@echo - etc/nginx/service-visit-history.conf
	@echo - ENV/.env.app
	@echo - ENV/.env.nginx

.PHONY: prod-pull-build
prod-pull-build:
	@echo Pulling docker images...
	docker-compose -f docker-compose.prod.yml pull nginx
	@echo Building docker images...
	docker-compose -f docker-compose.prod.yml build --pull

.PHONY: prod-up
prod-up:
	@echo Starting compose services...
	docker-compose -f docker-compose.prod.yml up --detach

.PHONY: prod-down
prod-down:
	@echo Stopping compose services...
	docker-compose -f docker-compose.prod.yml down

.PHONY: prod-start
prod-start: prod-pull-build prod-up

.PHONY: prod-restart
prod-restart: prod-pull-build prod-down prod-up

.PHONY: prod-logs
prod-logs:
	docker-compose -f docker-compose.prod.yml logs --follow --tail=50

.PHONY: help # Print list of targets with descriptions
help:
	@echo; \
		for mk in $(MAKEFILE_LIST); do \
			echo \# $$mk; \
			grep '^.PHONY: .* #' $$mk \
			| sed 's/\.PHONY: \(.*\) # \(.*\)/\1	\2/' \
			| expand -t20; \
			echo; \
		done
