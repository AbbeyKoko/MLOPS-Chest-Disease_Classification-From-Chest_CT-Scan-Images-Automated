FROM python:3.9.19-slim-buster

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        awscli \
        ca-certificates \
        curl \
        gnupg \
        unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . /app

RUN pip install --no-cache-dir --prefer-binary -r requirements.txt -i https://pypi.python.org/simple

CMD [ "python3", "app.py" ]