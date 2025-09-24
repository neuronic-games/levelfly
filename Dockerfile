FROM ruby:2.5.9

RUN sed -i 's/[^/.]*.debian.org/archive.debian.org/g' /etc/apt/sources.list

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update --allow-releaseinfo-change && apt-get install -y npm libpq-dev postgresql \ 
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/app
WORKDIR /var/app

# NOTE: Do this first to make cache invalidation happen less often, https://blog.saeloun.com/2022/07/12/docker-cache/
COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . /var/app

ARG DATABASE_URL=postgresql://localhost:5432 \
  RAILS_ENV=production \
  PUSHER_URL=https://example.com \
  PUSHER_SOCKET_URL=ws://example.com \
  SECRET_KEY_BASE=8e1f4c03075883a1fc379b58ed1212e96cc44e2e41443288f0786eb8da167230

# TODO: Investigate why DB connection is required here; see https://github.com/rails/rails/issues/25246
RUN pg_virtualenv -o 'listen_addresses="127.0.0.1"' -t bash -c ' \
  bundle exec rake assets:precompile && \
  bundle exec rake assets:clean'

EXPOSE 3000

CMD bundle exec rails s -b 0.0.0.0 -P /dev/null

RUN apt-get remove postgresql -y

# TODO: Multi-stage build to produce (smaller) devel and production images, the latter with `BUNDLE_WITHOUT=development:test`
