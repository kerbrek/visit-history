import time

import validators
from fastapi import FastAPI, Query, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse, RedirectResponse
from yarl import URL

from . import schemas
from .database import redis

app = FastAPI(docs_url="/docs.html", redoc_url=None)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):  # pylint: disable=unused-argument
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"status": str(exc), "detail": exc.errors()},
    )


@app.get("/", response_class=RedirectResponse)
async def redirect_to_docs():
    return "/docs.html"


@app.get(
    "/visited_domains",
    response_model=schemas.DomainsOut,
)
async def read_visited_domains(
    from_: int = Query(..., ge=0, description="unix time"),
    to: int = Query(..., ge=0, description="unix time"),
):
    if from_ > to:
        start = to
        end = from_
    else:
        start = from_
        end = to

    domains = set()
    keys = await redis.zrangebyscore("keys", min=start, max=end)

    if not keys:
        return {"domains": domains, "status": "ok"}

    async with redis.pipeline() as pipe:
        for key in keys:
            pipe.lrange(f"links:{key}", 0, -1)
        links_lists = await pipe.execute()

    for links in links_lists:
        for link in links:
            url = URL(link)
            if not url.is_absolute():
                url = URL(f"//{link}")

            domain = url.host.removesuffix(".")
            if validators.domain(domain):
                domains.add(domain)

    return {"domains": domains, "status": "ok"}


@app.post(
    "/visited_links",
    response_model=schemas.LinksOut,
    status_code=status.HTTP_201_CREATED,
)
async def write_visited_links(req: schemas.LinksIn):
    timestamp = int(time.time())
    await redis.zadd("keys", {timestamp: timestamp})
    await redis.rpush(f"links:{timestamp}", *req.links)
    return {"status": "ok"}
