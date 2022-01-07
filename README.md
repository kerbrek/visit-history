# Visit History

JSON API сервис для учета посещенных ссылок. Используется база _Redis_, фреймворк _FastAPI_ и асинхронная библиотека _aioredis_.

Запускается командой `make up` и доступен по адресу <http://127.0.0.1:8000/>.

Приложение предоставляет два HTTP ресурса.

- Ресурс загрузки посещений:

Запрос 1

`POST /visited_links`

```json
{
  "links": [
    "example.com",
    "http://кц.рф/",
    "https://www.google.com.",
    "https://www.google.com/search?q=fastapi",
    "aioredis.readthedocs.io/en/latest/"
  ]
}
```

Ответ 1

```json
{
  "status": "ok"
}
```

- Ресурс получения статистики:

Запрос 2

`GET /visited_domains?from_=1640991600&to=1640988000`

Ответ 2

```json
{
  "domains": [
    "example.com",
    "кц.рф",
    "www.google.com",
    "aioredis.readthedocs.io"
  ],
  "status": "ok"
}
```

## Prerequisites

- pipenv
- make
- docker
- docker-compose

## Commands

- Start _Docker Compose_ services

  `make up`

- Setup a working environment using _Pipenv_

  `make setup`

- Start development Web server (with database)

  `make start`

- Run tests

  `make test`

- Run linter

  `make lint`

- List all available _Make_ commands

  `make help`
