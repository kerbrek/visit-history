import time

import pytest
from httpx import AsyncClient
from visit_history.main import app, redis

links = [
    "example.com",
    "http://кц.рф/",
    "https://www.google.com.",
    "https://www.google.com/search?q=fastapi",
    "aioredis.readthedocs.io/en/latest/",
    "localhost",
    "http://127.0.0.1/",
    "https://bro^ken.com/",
]

domains = {
    "example.com",
    "кц.рф",
    "www.google.com",
    "aioredis.readthedocs.io",
}

params = {
    "from_": 0,
    "to": int(time.time()) + 60*60,
}

reversed_params = {
    "from_": params["to"],
    "to": params["from_"],
}


@pytest.fixture
async def init_db():
    await redis.flushdb()


@pytest.fixture
async def aclient():
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client


@pytest.mark.asyncio
async def test_write_links_read_domains(init_db, aclient):  # pylint: disable=unused-argument,redefined-outer-name
    response = await aclient.get("/visited_domains", params=params)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["domains"] == []

    response = await aclient.post("/visited_links", json={"links": links})
    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "ok"

    response = await aclient.get("/visited_domains", params=params)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert set(data["domains"]) == domains

    response = await aclient.get("/visited_domains", params=reversed_params)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert set(data["domains"]) == domains

    same_links_again = links
    response = await aclient.post("/visited_links", json={"links": same_links_again})
    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "ok"

    response = await aclient.get("/visited_domains", params=params)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert set(data["domains"]) == domains


@pytest.mark.asyncio
async def test_errors_writing_links_reading_domains(init_db, aclient):  # pylint: disable=unused-argument,redefined-outer-name
    zero_links = []
    response = await aclient.post("/visited_links", json={"links": zero_links})
    assert response.status_code == 422
    data = response.json()
    assert data["status"] != "ok"

    too_short_link = "t.c"
    too_long_link = f"http://example.com/{'a' * 2083}"
    response = await aclient.post(
        "/visited_links",
        json={"links": [too_short_link, too_long_link]},
    )
    assert response.status_code == 422
    data = response.json()
    assert data["status"] != "ok"

    negative_params = {"from_": -1, "to": -9}
    response = await aclient.get("/visited_domains", params=negative_params)
    assert response.status_code == 422
    data = response.json()
    assert data["status"] != "ok"
