FROM ubuntu:24.04
LABEL description="JSON Schema Utils Compiler Setup for Benchmarking with Java"

RUN mkdir -p /app
WORKDIR /app

# install this version from source
ARG JMC=main
ARG JSU=main

RUN apt update ; \
    apt upgrade -y ; \
    apt install -y --no-install-recommends --fix-missing \
        python3 python-is-python3 python3-venv python3-pip git \
        time jq curl vim ca-certificates

# force install, otherwise it would require a virtual environment
# RUN pip install --break-system-packages jsonschema-specifications
RUN pip install --break-system-packages "git+https://github.com/clairey-zx81/json-model@$JMC"
RUN pip install --break-system-packages "git+https://github.com/zx80/json-schema-utils@$JSU"

# python-version agnostic runtime directory guess
RUN echo "export JSU_RUNTIME=$(echo /usr/local/lib/python3.*/dist-packages/json_model/runtime)" > .env

# java-specific setup
RUN apt install -y --no-install-recommends --fix-missing \
        openjdk-21-jdk maven
RUN . /app/.env && cd $JSU_RUNTIME/java && mvn install
RUN echo -n "export CLASSPATH=/workspace:" >> .env
RUN find / -type f -name '*.jar' -print | \
    egrep "json-model|getopt|gson|jakarta|johnzon|jackson" | \
    grep -v "maven" | \
    tr '\012' ':' >> .env
RUN echo >> .env

COPY . .
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/generate-and-run.sh", "Java"]
