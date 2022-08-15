#Start with slim-buster
FROM python:3.10-slim-buster as venv

#Update apt and install curl functionality
RUN apt update \
    && apt install -y curl build-essential libffi-dev \
    && rm -rf /var/lib/apt/lists/*

#Install and setup poetry
ENV POETRY_VERSION=1.1.13
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH /root/.local/bin:$PATH

#setup directory for poetry
WORKDIR /lab4
COPY pyproject.toml poetry.lock ./

#run poetry to install requirements
RUN python -m venv --copies /lab4/venv
RUN . /lab4/venv/bin/activate\
    && poetry install --no-dev

#Create deployment with a slim version
FROM python:3.10-slim-buster as prod

#copy over venv from build
COPY --from=venv /lab4/venv /lab4/venv/
ENV PATH /lab4/venv/bin:$PATH

WORKDIR /lab4
COPY . ./

#healthcheck to make sure container is still running
HEALTHCHECK --start-period=10s --interval=30s CMD "curl http://localhost:8000/health"

#Start the listener service
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]