FROM mcr.microsoft.com/dotnet/sdk:8.0

COPY . /app
RUN dotnet tool install --global Corvus.Json.JsonSchema.TypeGeneratorTool --version 3.1.1
ENTRYPOINT ["/app/generate-and-run.sh"]
CMD []
