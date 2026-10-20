# Corvus.JsonSchema's native-backed Perl evaluator, JSON::Schema::Corvus::XS, from CPAN. Its Alien::CorvusJsonSchema
# downloads the corvus-json-schema C library's release package for the platform (checked against the digest it
# records), and the binding links its static library, so nothing of it is needed at run time.
FROM perl:5.42.3 AS build

RUN apt-get update && apt-get install -y --no-install-recommends jq \
 && rm -rf /var/lib/apt/lists/*

# The repository's releases: Docker downloads the list on every build and reuses the layers below only while it is
# unchanged, so a new release of JSON::Schema::Corvus::XS (tagged perl-xs-v<version>) is picked up by the next build.
ADD https://api.github.com/repos/corvus-dotnet/Corvus.JsonSchema/releases?per_page=100 /tmp/releases.json
RUN tag=$(jq -r '[.[] | select(.tag_name | startswith("perl-xs-v")) | select((.draft or .prerelease) | not)][0].tag_name' /tmp/releases.json) \
 && cpanm --notest Alien::Build Alien::Build::MM \
 && cpanm --notest -L /opt/perl5 "JSON::Schema::Corvus::XS@${tag#perl-xs-v}" \
 && mkdir -p /app && PERL5LIB=/opt/perl5/lib/perl5 perl -MJSON::Schema::Corvus::XS \
      -e 'print JSON::Schema::Corvus::XS->VERSION =~ s{^v}{}r' > /app/corvus-version

FROM perl:5.42.3-slim
RUN apt-get update && apt-get install -y --no-install-recommends time \
 && rm -rf /var/lib/apt/lists/*
COPY --from=build /opt/perl5 /opt/perl5
COPY --from=build /app/corvus-version /app/corvus-version
ENV PERL5LIB=/opt/perl5/lib/perl5
COPY . /app
ENTRYPOINT ["/app/memory-wrapper.sh", "perl", "/app/main.pl"]
CMD []
