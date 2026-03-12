FROM ubuntu:24.04
LABEL description="JSON Schema Utils Compiler Setup for Benchmarking with JavaScript"

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

# perl libre-engine-re2-perl libjson-maybexs-perl libcpanel-json-xs-perl libdatetime-hires-perl ; \

# force install, otherwise it would require a virtual environment
# RUN pip install --break-system-packages jsonschema-specifications
RUN pip install --break-system-packages "git+https://github.com/clairey-zx81/json-model@$JMC"
RUN pip install --break-system-packages "git+https://github.com/zx80/json-schema-utils@$JSU"

# python-version agnostic runtime directory guess
RUN echo "export JSU_RUNTIME=$(echo /usr/local/lib/python3.*/dist-packages/json_model/runtime)" > .env

# javascript specifc setup, nodejs >= 20.0.0
ARG nodejs=stable
ARG nre2=
RUN apt install libatomic1
ENV NVM_DIR=/usr/local/nvm
RUN mkdir -p $NVM_DIR
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
RUN . $NVM_DIR/nvm.sh && \
    nvm install $nodejs && \
    nvm alias default $nodejs && \
    nvm use default
RUN ln -s $NVM_DIR/versions/node/v* $NVM_DIR/versions/node/default
ENV PATH=$NVM_DIR/versions/node/default/bin:$PATH
ENV NODE_PATH=/app/node_modules
RUN echo '{"name":"jsu-benchmark","type":"module"}' | jq > package.json
# RUN npm install re2${nre2:+@$nre2}
# nodejs import does not honor NODE_PATH: https://nodejs.org/api/esm.html#no-node_path
RUN ln -s /app/node_modules /node_modules

# obscure issue with links…
# RUN source .env && npm install $JSU_RUNTIME/js
# install manually instead
RUN mkdir -p node_modules/json_model_runtime
RUN source .env && cp $JSU_RUNTIME/js/*.js /app/node_modules/json_model_runtime/

COPY . .
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/generate-and-run.sh", "JS"]
