FROM python:3.9.1 AS base-deps

WORKDIR /app

RUN apt update -y && apt install -y --no-install-recommends build-essential awscli && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN --mount=type=cache,target=/root/.cache \
  pip install --upgrade pip && \
  pip install --no-cache-dir --prefer-binary -r requirements.txt

FROM python:3.9.1-slim-buster

WORKDIR /app

COPY --from=base-deps /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=base-deps /usr/local/bin /usr/local/bin

COPY . .

EXPOSE 8081

CMD ["python3", "app.py"]
