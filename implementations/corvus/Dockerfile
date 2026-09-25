# The -aot image variants carry the native toolchain (clang, zlib) that native AOT publishing needs
FROM mcr.microsoft.com/dotnet/sdk:10.0.401-noble-aot

RUN apt-get update && apt-get install -y --no-install-recommends time && rm -rf /var/lib/apt/lists/*

COPY . /app
WORKDIR /app
RUN dotnet publish --configuration Release --output /app/publish
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/publish/bench"]
CMD []
