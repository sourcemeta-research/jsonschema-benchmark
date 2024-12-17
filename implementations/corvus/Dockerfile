FROM mcr.microsoft.com/dotnet/sdk:9.0

COPY . /app
RUN dotnet tool install --global Corvus.Json.JsonSchema.TypeGeneratorTool --version 4.0.12
ENTRYPOINT ["/app/generate-and-run.sh"]
CMD []
