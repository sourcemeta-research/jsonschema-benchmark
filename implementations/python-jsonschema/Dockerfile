FROM python:3.12.5-alpine

# Install uv
ADD --chmod=755 https://astral.sh/uv/install.sh /install.sh
RUN /install.sh && rm /install.sh

COPY . /app
RUN /root/.local/bin/uv sync --directory /app
ENTRYPOINT ["/root/.local/bin/uv", "run", "--directory", "/app", "validate.py"]
CMD []
