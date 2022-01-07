import multiprocessing
import os

import aioredis

WORKERS_DEFAULT = multiprocessing.cpu_count()
WORKERS = int(os.environ.get("WORKERS", WORKERS_DEFAULT))

REDIS_URL_TEMPLATE = "redis://{host}:{port}"
REDIS_URL = REDIS_URL_TEMPLATE.format(
    host=os.environ["REDIS_HOST"],
    port=os.environ["REDIS_PORT"],
)

REDIS_MAX_CONNECTIONS = int(os.environ.get("REDIS_MAX_CONNECTIONS", 10_000))
REDIS_POOL_SIZE_DEFAULT = REDIS_MAX_CONNECTIONS // WORKERS
REDIS_POOL_SIZE = int(os.environ.get(
    "REDIS_POOL_SIZE", REDIS_POOL_SIZE_DEFAULT))

redis = aioredis.from_url(
    REDIS_URL,
    decode_responses=True,
    max_connections=REDIS_POOL_SIZE,
)
