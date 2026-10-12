FROM mcr.microsoft.com/dotnet/sdk:10.0.401-noble AS build

# The package's version list: Docker downloads it on every build and reuses the layers below only while it is
# unchanged, so a new Corvus.Text.Json release is picked up by the next build.
ADD https://api.nuget.org/v3-flatcontainer/corvus.text.json/index.json /tmp/corvus-versions.json

COPY . /app
WORKDIR /app
RUN dotnet publish --configuration Release --use-current-runtime --output /app/publish \
 && grep -o '"Corvus.Text.Json/[0-9][^"]*"' obj/project.assets.json | head -n 1 | cut -d/ -f2 | tr -d '"' > /app/publish/corvus-version

FROM mcr.microsoft.com/dotnet/runtime-deps:10.0-noble
RUN apt-get update && apt-get install -y --no-install-recommends time && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/publish /app/publish
COPY memory-wrapper.sh /app/memory-wrapper.sh
RUN cp /app/publish/corvus-version /app/corvus-version
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/publish/bench"]
CMD []
