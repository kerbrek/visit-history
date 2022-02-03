#################################################################
####################### BUILD STAGE #############################
#################################################################
FROM python:3.9-slim-bullseye as builder

RUN python -m pip install --no-cache-dir pipfile-requirements==0.3.0

WORKDIR /app

RUN python -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

COPY Pipfile.lock /tmp/
RUN pipfile2req --hashes /tmp/Pipfile.lock > /tmp/requirments.txt \
    && pipfile2req --dev --hashes /tmp/Pipfile.lock > /tmp/requirments-dev.txt \
    && pip install --no-cache-dir --require-hashes -r /tmp/requirments.txt

#################################################################
####################### TARGET STAGE ############################
#################################################################
FROM python:3.9-slim-bullseye

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

RUN groupadd --system --gid 999 app \
    && useradd --system --uid 999 --gid app app
USER app

WORKDIR /app

COPY --chown=app:app --from=builder /app/venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

COPY --chown=app:app . /app

EXPOSE 8000

ENTRYPOINT ["/app/docker/entrypoint.sh"]

CMD ["gunicorn", "--config", "./gunicorn.conf.py", "visit_history.main:app"]
