FROM golang:1.23-alpine3.21

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time

WORKDIR /app
COPY . .
RUN go mod download && go build -o gojsonschema_validator .
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/gojsonschema_validator"]
CMD []
