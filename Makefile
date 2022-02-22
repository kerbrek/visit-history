.DEFAULT_GOAL := help

SHELL := /usr/bin/env bash

project := visit_history

docker_user := kerbrek
docker_image := visit-history-web

git_commit := $(shell git rev-parse --short HEAD)
git_branch := $(shell git rev-parse --abbrev-ref HEAD)

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

.PHONY: start # Start development Web server
start: prepare-temp-containers
	@sleep 1
	@trap '${stop-prepared-temp-containers}' EXIT && \
		echo Starting application... && \
		env PIPENV_DOTENV_LOCATION=.env.example \
			pipenv run uvicorn ${project}.main:app --reload

.PHONY: requirements # Generate requirements.txt file
requirements:
	pipenv lock --requirements > requirements.txt

.PHONY: up # Start Compose services
up:
	docker-compose -p ${project} -f docker/docker-compose.yml pull redis nginx
	docker-compose -p ${project} -f docker/docker-compose.yml build --pull
	docker-compose -p ${project} -f docker/docker-compose.yml up

.PHONY: down # Stop Compose services
down:
	docker-compose -p ${project} -f docker/docker-compose.yml down

.PHONY: up-dev # Start Compose services (development)
up-dev:
	docker-compose -p ${project} -f docker/docker-compose.dev.yml pull redis
	docker-compose -p ${project} -f docker/docker-compose.dev.yml build --pull
	docker-compose -p ${project} -f docker/docker-compose.dev.yml up

.PHONY: down-dev # Stop Compose services (development)
down-dev:
	docker-compose -p ${project} -f docker/docker-compose.dev.yml down

.PHONY: up-debug # Start Compose services (debug)
up-debug:
	docker-compose -p ${project} -f docker/docker-compose.debug.yml pull redis
	docker-compose -p ${project} -f docker/docker-compose.debug.yml build --pull
	docker-compose -p ${project} -f docker/docker-compose.debug.yml up

.PHONY: down-debug # Stop Compose services (debug)
down-debug:
	docker-compose -p ${project} -f docker/docker-compose.debug.yml down

.PHONY: build # Build Docker image
build:
	docker build --pull \
		--file docker/Dockerfile \
		--tag ${docker_image}:${git_commit} \
		--tag ${docker_image}:latest \
		.

.PHONY: release # Push Docker image to the registry
release: build
	docker tag ${docker_image}:${git_commit} ${docker_user}/${docker_image}:${git_commit}
	docker tag ${docker_image}:latest ${docker_user}/${docker_image}:latest
	docker push ${docker_user}/${docker_image}:${git_commit}
	docker push ${docker_user}/${docker_image}:latest

.PHONY: deploy # Deploy application
deploy:
	cd ansible/ && ansible-playbook playbook.yml -i inventory.ini

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
