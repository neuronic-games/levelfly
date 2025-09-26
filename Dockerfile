FROM ruby:3.3.9-slim

ARG DEBIAN_FRONTEND=noninteractive

ARG DEBIAN_PACKAGES_BUILD="npm libpq-dev libyaml-dev"

RUN apt-get update --allow-releaseinfo-change && apt-get install -y ${DEBIAN_PACKAGES_BUILD} file \ 
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/app
WORKDIR /var/app

# NOTE: Do this first to make cache invalidation happen less often, https://blog.saeloun.com/2022/07/12/docker-cache/
COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . /var/app

ARG DATABASE_URL=nulldb://nulldb \
  RAILS_ENV=production \
  PUSHER_URL=https://example.com \
  PUSHER_SOCKET_URL=ws://example.com \
  SECRET_KEY_BASE_DUMMY=1 \
  COMPILE_ASSETS=1

RUN bundle exec rake assets:precompile && \
  bundle exec rake assets:clean

RUN apt-get remove -y ${DEBIAN_PACKAGES_FILE}

EXPOSE 3000

CMD bundle exec rails s -b 0.0.0.0 -P /dev/null

# TODO: Multi-stage build to produce (smaller) devel and production images, the latter with `BUNDLE_WITHOUT=development:test`
