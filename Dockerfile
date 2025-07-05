FROM python:3.9-slim-buster

RUN apt update -y && apt install awscli -y

WORKDIR /app

COPY . /app

COPY requirements.txt .

RUN pip install --no-cache-dir --prefer-binary -r requirements.txt -i https://pypi.python.org/simple

CMD [ "python3", "app.py" ]