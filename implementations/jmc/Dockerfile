FROM ubuntu
LABEL description="JSON Model Compiler Setup for Benchmarking"

# system update and installs
RUN echo system 3
RUN apt update
RUN apt upgrade -y
RUN apt install -y --no-install-recommends --fix-missing \
        vim git ca-certificates libtool m4 time automake make pkgconf gcc g++ texinfo jq \
        libpcre2-dev libre2-dev libjansson-dev \
        python3 python-is-python3 python3-venv python3-pip \
        npm nodejs
RUN apt clean

# compile cre2 into /usr/local
RUN git clone https://github.com/marcomaggi/cre2.git
RUN cd cre2 ; \
    sh autogen.sh ; \
    ./configure --enable-maintainer-mode ; \
    make ; \
    make install

# setup python environment, native pip complains about direct installations otherwise
RUN python -m venv /venv
RUN /venv/bin/pip install -U pip

# application dependencies
RUN mkdir /app
WORKDIR /app
RUN echo '{"name":"jmc-benchmark","type":"module"}' | jq > package.json
RUN npm install re2

# actual application stuff
RUN echo jmc 7
# direct install json-model and json-schema-utils from github
RUN git clone https://github.com/clairey-zx81/json-model.git
RUN git clone https://github.com/zx80/json-schema-utils.git

RUN /venv/bin/pip install -e ./json-model ./json-schema-utils
RUN npm install file:./json-model/js_runtime

# setup benchmarking scripts
COPY . /app
ENV LD_LIBRARY_PATH=/usr/local/lib
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/generate-and-run.sh"]
