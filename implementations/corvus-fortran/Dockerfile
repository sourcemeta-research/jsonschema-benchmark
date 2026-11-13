FROM gcc:latest

RUN apt-get update && apt-get install -y --no-install-recommends time jq && rm -rf /var/lib/apt/lists/*

# The C library: Docker downloads the repository's list of releases on every build and reuses the layers below only
# while it is unchanged, so a new release of the C library (tagged capi-v<version>) is picked up by the next build.
ADD https://api.github.com/repos/corvus-dotnet/Corvus.JsonSchema/releases?per_page=100 /tmp/releases.json
RUN tag=$(jq -r '[.[] | select(.tag_name | startswith("capi-v")) | select((.draft or .prerelease) | not)][0].tag_name' /tmp/releases.json) \
 && version=${tag#capi-v} \
 && name="corvus-json-schema-$version-$(uname -m)-unknown-linux-gnu" \
 && curl -sSfL "https://github.com/corvus-dotnet/Corvus.JsonSchema/releases/download/$tag/$name.tar.gz" | tar -xz -C /opt \
 && mv "/opt/$name" /opt/corvus-json-schema

# The Fortran binding, from its latest release (tagged v<version>), in the same way.
ADD https://api.github.com/repos/corvus-dotnet/corvus-json-schema-fortran/releases/latest /tmp/fortran-release.json
RUN tag=$(jq -r .tag_name /tmp/fortran-release.json) \
 && mkdir -p /opt/corvus-json-schema-fortran /app \
 && curl -sSfL "https://github.com/corvus-dotnet/corvus-json-schema-fortran/archive/refs/tags/$tag.tar.gz" \
    | tar -xz -C /opt/corvus-json-schema-fortran --strip-components=1 \
 && echo "${tag#v}" > /app/corvus-version

COPY . /app
# The binding's module and the benchmark, linked statically with the C library, as Blaze is.
RUN mkdir -p /app/build && cd /app/build \
 && gfortran -O3 -std=f2018 -o corvus_fortran_benchmark /opt/corvus-json-schema-fortran/src/corvus_json_schema.f90 \
      /app/main.f90 /opt/corvus-json-schema/lib/libcorvus_json_schema.a -lpthread -ldl -lm
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/build/corvus_fortran_benchmark"]
CMD []
