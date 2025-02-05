FROM ruby:3.4.1-alpine3.21

RUN apk add --no-cache build-base

COPY . /app
RUN bundle install --gemfile /app/Gemfile
ENTRYPOINT ["bundle", "exec", "--gemfile", "/app/Gemfile", "ruby", "/app/main.rb"]
CMD []
