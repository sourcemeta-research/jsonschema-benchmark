# Use the official Golang image as a parent image
FROM golang:1.23-alpine

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container
COPY . .

# Download dependencies
RUN go mod download

# Build the Go app
RUN go build -o go_jsonschema_validator .

# Run the binary
ENTRYPOINT ["/app/go_jsonschema_validator"]
CMD []

