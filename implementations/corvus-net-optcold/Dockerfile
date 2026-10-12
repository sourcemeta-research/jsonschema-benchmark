# The -aot image variants carry the native toolchain (clang, zlib) that native AOT publishing needs
FROM mcr.microsoft.com/dotnet/sdk:10.0.401-noble-aot

RUN apt-get update && apt-get install -y --no-install-recommends time && rm -rf /var/lib/apt/lists/*

# The package's version list: Docker downloads it on every build and reuses the layers below only while it is
# unchanged, so a new Corvus.Text.Json release is picked up by the next build.
ADD https://api.nuget.org/v3-flatcontainer/corvus.text.json/index.json /tmp/corvus-versions.json

COPY . /app
WORKDIR /app
RUN dotnet publish --configuration Release --output /app/publish \
 && grep -o '"Corvus.Text.Json/[0-9][^"]*"' obj/project.assets.json | head -n 1 | cut -d/ -f2 | tr -d '"' > /app/corvus-version
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/publish/bench"]
CMD []
