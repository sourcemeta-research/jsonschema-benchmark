FROM mcr.microsoft.com/dotnet/sdk:10.0.100-alpine3.22

# Note: coreutils is necessary so /usr/bin/date can use nanoseconds
RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community coreutils time

COPY . /app
RUN dotnet tool install --global Corvus.Json.JsonSchema.TypeGeneratorTool --version 4.3.21
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/generate-and-run.sh"]
CMD []
