FROM mcr.microsoft.com/dotnet/sdk:9.0.102-alpine3.21

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time

COPY . /app
WORKDIR /app
RUN dotnet build --configuration=Release
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/bin/Release/net9.0/bench"]
CMD []

