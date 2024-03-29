# Dockerfile
# gets the docker parent image
FROM ruby:2.4.10

RUN apt update && apt install -y npm libpq-dev \ 
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/app
COPY . /var/app
WORKDIR /var/app

RUN bundle install
RUN bundle exec rake assets:precompile
RUN bundle exec rake assets:clean
EXPOSE 3000
CMD rails s -b 0.0.0.0 -P /dev/null
