FROM mcr.microsoft.com/dotnet/sdk:9.0.102-alpine3.21

COPY . /app
RUN dotnet tool install --global Corvus.Json.JsonSchema.TypeGeneratorTool --version 4.2.3
ENTRYPOINT ["/app/generate-and-run.sh"]
CMD []
