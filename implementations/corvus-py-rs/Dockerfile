FROM python:3.13.1-alpine3.21

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time

# Install uv
ADD --chmod=755 https://astral.sh/uv/install.sh /install.sh
RUN /install.sh && rm /install.sh

# The package's PyPI index page: Docker downloads it on every build and reuses the layers below only while it is
# unchanged, so a new corvus-json-schema-rs release is picked up by the next build.
ADD https://pypi.org/simple/corvus-json-schema-rs/ /tmp/corvus-index

COPY . /app
RUN /root/.local/bin/uv lock --directory /app --upgrade-package corvus-json-schema-rs \
 && /root/.local/bin/uv sync --directory /app --locked \
 && /app/.venv/bin/python -c "import corvus_json_schema_rs; print(corvus_json_schema_rs.__version__)" > /app/corvus-version
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/.venv/bin/python", "/app/validate.py"]
CMD []
