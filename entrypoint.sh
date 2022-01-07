#!/bin/bash

./wait-for-it.sh "${REDIS_HOST}:${REDIS_PORT}"

exec "$@"
