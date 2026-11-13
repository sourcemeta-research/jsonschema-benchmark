FROM gcc:latest

RUN apt-get update && apt-get install -y --no-install-recommends cmake time rapidjson-dev && rm -rf /var/lib/apt/lists/*

# valijson is header-only: install the headers of its release.
ARG VALIJSON_VERSION=v1.1.4
RUN git clone --depth 1 --branch "$VALIJSON_VERSION" https://github.com/tristanpenman/valijson.git /tmp/valijson \
 && cmake -S /tmp/valijson -B /tmp/valijson/build -Dvalijson_BUILD_TESTS=OFF && cmake --install /tmp/valijson/build \
 && rm -rf /tmp/valijson

COPY . /app
RUN g++ -O3 -std=c++17 -o /app/valijson_benchmark /app/main.cpp
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/valijson_benchmark"]
CMD []
