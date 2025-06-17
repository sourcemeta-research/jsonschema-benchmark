FROM ruby:3.4.1-alpine3.21

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time
RUN apk add --no-cache build-base

COPY . /app
RUN bundle install --gemfile /app/Gemfile
ENTRYPOINT ["/app/memory-wrapper.sh", "bundle", "exec", "--gemfile", "/app/Gemfile", "ruby", "/app/main.rb"]
CMD []
