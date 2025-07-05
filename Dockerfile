FROM jupyter/tensorflow-notebook:latest

RUN apt update -y && apt install awscli -y

WORKDIR /app

COPY . /app

RUN pip install --no-cache-dir --prefer-binary -r requirements_simplified.txt -i https://pypi.python.org/simple

CMD [ "python3", "app.py" ]