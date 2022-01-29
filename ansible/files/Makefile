.DEFAULT_GOAL := help

SHELL := /usr/bin/env bash

.PHONY: prod-pull # Pull docker images
prod-pull:
	@echo Pulling docker images...
	docker-compose pull

.PHONY: prod-up # Start compose services
prod-up:
	@echo Starting compose services...
	docker-compose up --detach

.PHONY: prod-down # Stop compose services
prod-down:
	@echo Stopping compose services...
	docker-compose down

.PHONY: prod-restart # Restart compose services
prod-restart: prod-pull prod-down prod-up

.PHONY: prod-logs # Displays log output from services
prod-logs:
	docker-compose logs --follow --tail=50

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
