# syntax=docker.io/docker/dockerfile:1.7-labs
FROM gcc:latest

RUN apt-get update && apt-get install -y --no-install-recommends cmake time && rm -rf /var/lib/apt/lists/*

# Add a placeholder for main so we can cache dependency builds
COPY --exclude=./main.cc . /app
RUN echo "int main(int argc, char**argv){}" > /app/main.cc

RUN git clone -b v1.1.0 https://github.com/Tencent/rapidjson/ /app/repo
RUN cmake -S /app -B /app/build -DCMAKE_BUILD_TYPE:STRING=Release -DBUILD_SHARED_LIBS:BOOL=OFF
RUN cmake --build /app/build --config Release --parallel 4

# Rebuild with the real source
COPY ./main.cc /app
RUN touch /app/main.cc
RUN cmake --build /app/build --config Release --parallel 4

ENTRYPOINT ["/app/memory-wrapper.sh", "/app/build/rapidjson_benchmark"]
CMD []
