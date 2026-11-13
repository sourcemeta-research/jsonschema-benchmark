FROM python:3.13.1-alpine3.21

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time

# Install uv
ADD --chmod=755 https://astral.sh/uv/install.sh /install.sh
RUN /install.sh && rm /install.sh

COPY . /app
RUN /root/.local/bin/uv sync --directory /app --locked
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/.venv/bin/python", "/app/validate.py"]
CMD []
