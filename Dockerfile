# Dockerfile
# gets the docker parent image
FROM ruby:2.4.10

RUN apt update && apt install -y npm libpq-dev \ 
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/app
COPY . /var/app
WORKDIR /var/app

RUN bundle install
EXPOSE 3000
CMD rails s -b 0.0.0.0
#CMD bundle exec rake jobs:work & rails s
