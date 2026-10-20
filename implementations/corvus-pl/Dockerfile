# Corvus.JsonSchema's pure-Perl evaluator, JSON::Schema::Corvus, from CPAN. It has no dependency beyond Perl's core.
FROM perl:5.42.3-slim

RUN apt-get update && apt-get install -y --no-install-recommends time jq \
 && rm -rf /var/lib/apt/lists/*

# The repository's releases: Docker downloads the list on every build and reuses the layers below only while it is
# unchanged, so a new release of JSON::Schema::Corvus (tagged perl-v<version>) is picked up by the next build.
ADD https://api.github.com/repos/corvus-dotnet/Corvus.JsonSchema/releases?per_page=100 /tmp/releases.json
RUN tag=$(jq -r '[.[] | select(.tag_name | startswith("perl-v")) | select((.draft or .prerelease) | not)][0].tag_name' /tmp/releases.json) \
 && cpanm --notest "JSON::Schema::Corvus@${tag#perl-v}" && rm -rf /root/.cpanm \
 && mkdir -p /app && perl -MJSON::Schema::Corvus -e 'print JSON::Schema::Corvus->VERSION =~ s{^v}{}r' > /app/corvus-version

COPY . /app
ENTRYPOINT ["/app/memory-wrapper.sh", "perl", "/app/main.pl"]
CMD []
