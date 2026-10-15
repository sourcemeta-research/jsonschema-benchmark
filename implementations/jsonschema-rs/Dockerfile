FROM python:3.13.1-alpine3.21

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time

# Install uv
ADD --chmod=755 https://astral.sh/uv/install.sh /install.sh
RUN /install.sh && rm /install.sh

# The package's PyPI index page: Docker downloads it on every build and reuses the layers below only while it is
# unchanged, so a new jsonschema-rs release is picked up by the next build.
ADD https://pypi.org/simple/jsonschema-rs/ /tmp/jsonschema-rs-index

COPY . /app
RUN /root/.local/bin/uv lock --directory /app --upgrade-package jsonschema-rs \
 && /root/.local/bin/uv sync --directory /app --locked \
 && /app/.venv/bin/python -c "import importlib.metadata; print(importlib.metadata.version('jsonschema-rs'))" > /app/jsonschema-rs-version
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/.venv/bin/python", "/app/validate.py"]
CMD []
