FROM ubuntu:24.04
LABEL description="JSON Schema Utils Compiler Setup for Benchmarking with Python"

RUN mkdir -p /app
WORKDIR /app

# install from source
ARG JMC=main
ARG JSU=main

RUN apt update ; \
    apt upgrade -y ; \
    apt install -y --no-install-recommends --fix-missing \
        python3 python-is-python3 python3-venv python3-pip git \
        time jq curl vim ca-certificates

# version caching and force install, otherwise it would require a virtual environment
RUN curl -s "https://api.github.com/repos/clairey-zx81/json-model/commits/${JMC}" | \
    jq -c "{jmc: .sha}" >> /app/commits.jsonl
RUN pip install --break-system-packages "git+https://github.com/clairey-zx81/json-model@$JMC"

RUN curl -s "https://api.github.com/repos/zx80/json-schema-utils/commits/${JSU}" | \
    jq -c "{jsu: .sha}" >> /app/commits.jsonl
RUN pip install --break-system-packages "git+https://github.com/zx80/json-schema-utils@$JSU"

RUN echo "export JSU_RUNTIME=$(jsu-compile --runtime)" > .env

# python-specific settings
RUN echo "export PYTHONPATH=/app" >> .env

COPY . .
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/benchmark.sh"]
