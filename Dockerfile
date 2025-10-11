ARG DEBIAN_PACKAGES_BUILD="npm libyaml-dev build-essential libpq-dev" \
  DEBIAN_PACKAGES_RUN="file shared-mime-info libpq5" \
  DEBIAN_FRONTEND=noninteractive

FROM ruby:3.3.9-slim AS base

ARG DEBIAN_PACKAGES_BUILD \
  DEBIAN_PACKAGES_RUN \
  DEBIAN_FRONTEND

RUN apt-get update --allow-releaseinfo-change && apt-get install --no-install-recommends -y ${DEBIAN_PACKAGES_BUILD} ${DEBIAN_PACKAGES_RUN} \ 
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

RUN mkdir -p /var/app
WORKDIR /var/app

# NOTE: Do this first to make cache invalidation happen less often, https://blog.saeloun.com/2022/07/12/docker-cache/
COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . /var/app

FROM base AS dev

ENV RAILS_ENV=development

EXPOSE 3000

CMD bundle exec rails s -b 0.0.0.0 -P /dev/null

FROM base AS assets

ARG RAILS_ENV=production

ARG DATABASE_URL=nulldb://nulldb \
  PUSHER_URL=https://example.com \
  PUSHER_SOCKET_URL=ws://example.com \
  SECRET_KEY_BASE_DUMMY=1 \
  COMPILE_ASSETS=1

RUN bundle exec rake assets:precompile && \
  bundle exec rake assets:clean

FROM ruby:3.3.9-slim AS prod

ARG DEBIAN_PACKAGES_BUILD \
  DEBIAN_PACKAGES_RUN \
  DEBIAN_FRONTEND

RUN mkdir -p /var/app
WORKDIR /var/app

COPY --from=base /usr/local/bundle/ /usr/local/bundle/
COPY --from=base /usr/local/lib/ruby/gems/3.3.0/ /usr/local/lib/ruby/gems/3.3.0/

COPY --from=assets /var/app/ /var/app/

RUN apt-get update --allow-releaseinfo-change && apt-get install --no-install-recommends -y ${DEBIAN_PACKAGES_RUN} \ 
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

EXPOSE 3000

CMD bundle exec rails s -b 0.0.0.0 -P /dev/null
