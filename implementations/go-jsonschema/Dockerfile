# Use the official Golang image as a parent image
FROM golang:1.23-alpine3.21

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container
COPY . .

# Download dependencies
RUN go mod download

# Build the Go app
RUN go build -o go_jsonschema_validator .

# Run the binary
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/go_jsonschema_validator"]
CMD []

