FROM ubuntu:24.04
LABEL description="JSON Model Compiler Setup for Benchmarking"

# versions:
ARG nodejs=stable
ARG cre2=master
ARG nre2=
ARG jmc=main
ARG jsu=main

# unversions - the version of these stem from ubuntu:
# - gcc/g++
# - python
# - pcre2
# - re2
# - jansson

# system update and installs
RUN apt update ; \
    apt upgrade -y ; \
    apt install -y --no-install-recommends --fix-missing \
        vim git ca-certificates libtool m4 time automake make pkgconf gcc g++ texinfo jq curl \
        libpcre2-dev libre2-dev libjansson-dev \
        python3 python-is-python3 python3-venv python3-pip \
        perl libre-engine-re2-perl libjson-maybexs-perl libcpanel-json-xs-perl libdatetime-hires-perl ; \
    apt clean

# compile cre2 into /usr/local
RUN git clone -b $cre2 https://github.com/marcomaggi/cre2.git
RUN cd cre2 ; \
    sh autogen.sh ; \
    ./configure --enable-maintainer-mode ; \
    make ; \
    make install
ENV LD_LIBRARY_PATH=/usr/local/lib

# setup python environment, native pip complains about direct installations otherwise
RUN python -m venv /venv
RUN /venv/bin/pip install -U pip

# application
RUN mkdir /app
WORKDIR /app

# nodejs >= 20.0.0
ENV NVM_DIR=/usr/local/nvm
RUN mkdir -p $NVM_DIR
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
RUN . $NVM_DIR/nvm.sh && \
	nvm install $nodejs && \
    nvm alias default $nodejs && \
    nvm use default
RUN ln -s $NVM_DIR/versions/node/v* $NVM_DIR/versions/node/default
ENV PATH=$NVM_DIR/versions/node/default/bin:$PATH
ENV NODE_PATH=/app/node_modules
RUN echo '{"name":"jmc-benchmark","type":"module"}' | jq > package.json
RUN npm install re2${nre2:+@$nre2}
# nodejs import does not honor NODE_PATH: https://nodejs.org/api/esm.html#no-node_path
RUN ln -s /app/node_modules /node_modules

# actual application stuff
# direct install json-model and json-schema-utils from github
RUN git clone -b $jmc https://github.com/clairey-zx81/json-model.git
RUN git clone -b $jsu https://github.com/zx80/json-schema-utils.git

# python setup
RUN /venv/bin/pip install -e ./json-model ./json-schema-utils
ENV PATH=/venv/bin:$PATH

# js runtime
RUN npm install file:./json-model/json_model/runtime/js

# perl runtime
ENV PERLLIB=/app/json-model/json_model/runtime/pl/lib

# setup benchmarking scripts
COPY . /app
ENV PATH=$PATH:.
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/generate-and-run.sh"]
