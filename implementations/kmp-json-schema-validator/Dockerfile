# syntax=docker.io/docker/dockerfile:1.7-labs
FROM gradle:8.11.1-jdk21

COPY --exclude=./app/src . /app

WORKDIR /app

# Just download dependencies first
RUN gradle downloadDependencies

# Now copy in the source and compile
COPY ./app/src /app/app/src
RUN gradle compileKotlin

ENTRYPOINT ["/app/run.sh"]
CMD []
