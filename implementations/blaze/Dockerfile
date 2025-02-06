# syntax=docker.io/docker/dockerfile:1.7-labs
FROM alpine:3.21.2
ARG BLAZE_BRANCH="main"

RUN apk add --no-cache git build-base cmake

# Add a placeholder for main so we can cache dependency builds
COPY --exclude=./main.cc . /app
RUN echo "int main(int argc, char**argv){}" > /app/main.cc

RUN git clone -b ${BLAZE_BRANCH} https://github.com/sourcemeta/blaze /app/repo
RUN cmake -S /app -B /app/build -DCMAKE_BUILD_TYPE:STRING=Release -DBUILD_SHARED_LIBS:BOOL=OFF
RUN cmake --build /app/build --config Release --parallel 4

# Rebuild with the real source
COPY ./main.cc /app
RUN touch /app/main.cc
RUN cmake --build /app/build --config Release --parallel 4

ENTRYPOINT ["/app/build/blaze_benchmark"]
CMD []
