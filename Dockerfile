FROM jupyter/tensorflow-notebook:latest

USER root

RUN apt update -y && apt install awscli -y

USER ${NB_UID}

WORKDIR /app

COPY . /app

RUN pip install --no-cache-dir --prefer-binary -r requirements_simplified.txt -i https://pypi.python.org/simple

CMD [ "python3", "app.py" ]