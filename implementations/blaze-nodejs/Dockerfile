FROM node:22-slim

# RUN apk add --no-cache git build-base clang python3 cmake
RUN apt-get update && \
    apt-get install -y git build-essential clang python3 cmake && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    apt-get autoclean -y && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/emscripten-core/emsdk.git /emsdk
RUN /emsdk/emsdk install 3.1.58
RUN /emsdk/emsdk activate 3.1.58 --permanent

RUN rm -rf /emsdk/upstream/emscripten/cmake
ENV PATH="/emsdk:/emsdk/upstream/emscripten:${PATH}"
ENV EMSDK="/emsdk"
ENV EM_CONFIG="/emsdk/.emscripten"

COPY . /app
RUN git clone https://github.com/sourcemeta/blaze /app/repo
RUN make -C /app/repo/bindings/nodejs compile

ENTRYPOINT ["node", "--disable-warning=ExperimentalWarning", "/app/main.mjs"]
CMD []
