FROM ruby:2.4.10-alpine as build

RUN apk add --no-cache \
  build-base \
  gcc \
  libc-dev \
  postgresql-dev

RUN mkdir -p /var/app
WORKDIR /var/app
COPY Gemfile* /var/app/

RUN bundle install

RUN apk add --no-cache \
  npm \
  tzdata

COPY . /var/app
RUN bundle exec rake assets:precompile
RUN bundle exec rake assets:clean

## main image
FROM ruby:2.4.10-alpine

RUN apk add --no-cache \
  postgresql tzdata

RUN mkdir -p /var/app
WORKDIR /var/app
COPY --from=build /var/app /var/app

RUN bundle config --local path vendor/bundle
RUN bundle config --local without development:test:assets

EXPOSE 3000
CMD rails s -b 0.0.0.0 -P /dev/null
