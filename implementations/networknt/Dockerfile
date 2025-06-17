# syntax=docker.io/docker/dockerfile:1.7-labs
FROM gradle:8.12.1-jdk23-alpine

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time

COPY --exclude=./app/src . /app

WORKDIR /app

# Just download dependencies first
RUN gradle downloadDependencies

# Now copy in the source and compile
COPY ./app/src /app/app/src
RUN gradle compileJava

ENTRYPOINT ["/app/memory-wrapper.sh", "/app/run.sh"]
CMD []
