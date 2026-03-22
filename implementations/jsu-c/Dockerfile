FROM ubuntu:24.04
LABEL description="JSON Schema Utils Compiler Setup for Benchmarking with C"

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
RUN echo "export JSU_RUNTIME=$(jsu-compile --runtime)" > .env

# c-specific setup
RUN apt install -y --no-install-recommends --fix-missing \
        libtool m4 automake make pkgconf gcc g++ texinfo \
        libpcre2-dev libre2-dev libjansson-dev

# compile cre2 (re2 wrapper for C) into /usr/local
ARG cre2=master
RUN git clone -b $cre2 https://github.com/marcomaggi/cre2.git ; \
    cd cre2 ; \
    sh autogen.sh ; \
    ./configure --enable-maintainer-mode ; \
    make ; \
    make install ; \
    cd .. ; \
	rm -rf cre2
ENV LD_LIBRARY_PATH=/usr/local/lib
ENV PATH=$PATH:.

COPY . .
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/benchmark.sh"]
