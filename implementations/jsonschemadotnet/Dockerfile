FROM mcr.microsoft.com/dotnet/sdk:8.0

COPY . /app
WORKDIR /app
RUN dotnet build --configuration=Release
ENTRYPOINT ["/app/bin/Release/net8.0/bench"]
CMD []

