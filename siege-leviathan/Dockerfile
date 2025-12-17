# --- base builder stage ----
# use the official python image we can declare version as variable
ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}-slim AS base
# PYTHONUNBUFFERED: prevents python from buffering stdout/stderror
# PYTHONDONTWRITEBYTECODE: prevents .pyc file creation
# UV_NO_DEV: do not install dev dependencies
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_NO_DEV=1
# set the working directory inside the container
WORKDIR /app
# create the certs directory explicitly
RUN mkdir certs secrets
# copy uv from the official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
# copy dependency definitions
COPY pyproject.toml uv.lock ./
# install the dependencies
RUN uv sync --locked
# ensure python and uvicorn commands use the installed packages
ENV PATH="/app/.venv/bin:$PATH"

# --- runtime stage ---
# copy the vault binary from the official image
COPY --from=hashicorp/vault:latest /bin/vault /bin/vault
# copy the source code into the contianer
COPY app ./app
# copy the startup script over
COPY startup.sh .
# make it executable
RUN chmod +x startup.sh

# document that the container listen on port 8003
EXPOSE 8003
# use a command that starts the agent and the app
CMD ["./startup.sh"]




