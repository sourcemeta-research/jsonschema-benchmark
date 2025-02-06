FROM mcr.microsoft.com/dotnet/sdk:9.0.102-alpine3.21

COPY . /app
WORKDIR /app
RUN dotnet build --configuration=Release
ENTRYPOINT ["/app/bin/Release/net9.0/bench"]
CMD []

