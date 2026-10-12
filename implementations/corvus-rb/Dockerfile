FROM ruby:3.4.1-alpine3.21

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time

# The gem's latest version: Docker downloads it on every build and reuses the layers below only while it is
# unchanged, so a new corvus_json_schema release is picked up by the next build.
ADD https://rubygems.org/api/v1/versions/corvus_json_schema/latest.json /tmp/corvus-latest.json

# Bundler installs the precompiled gem for the platform (x86_64-linux-musl or aarch64-linux-musl here). This
# image's "gem install" (RubyGems 3.6) ranks the glibc gem (x86_64-linux) equal to the musl one and can install
# it, and that one does not load on Alpine.
COPY . /app
RUN bundle install --gemfile /app/Gemfile \
 && ruby -rcorvus_json_schema -e 'print Gem.loaded_specs["corvus_json_schema"].version' > /app/corvus-version
ENTRYPOINT ["/app/memory-wrapper.sh", "ruby", "/app/main.rb"]
CMD []
