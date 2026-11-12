FROM gcc:latest

RUN apt-get update && apt-get install -y --no-install-recommends cmake time libre2-dev libabsl-dev \
 && rm -rf /var/lib/apt/lists/*

# The IRIS release Bowtie tests, built as a library beside the benchmark (as Bowtie's harness builds it).
ARG IRIS_VERSION=v0.1.0
RUN git clone --depth 1 --branch "$IRIS_VERSION" https://github.com/Cobra007-star-source/IRIS.git /app/iris

COPY . /app
RUN cmake -S /app -B /app/build -DCMAKE_BUILD_TYPE=Release && cmake --build /app/build --parallel 4
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/build/iris_benchmark"]
CMD []
