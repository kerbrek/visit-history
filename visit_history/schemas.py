from typing import List

from pydantic import BaseModel, conlist, constr


class LinksIn(BaseModel):
    links: conlist(
        constr(min_length=4, max_length=2083, strict=True),
        min_items=1,
    )


class LinksOut(BaseModel):
    status: str


class DomainsOut(BaseModel):
    status: str
    domains: List[constr(min_length=4, max_length=253, strict=True)]
