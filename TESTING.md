# Testing

Run all tests:

```
RAILS_ENV=test URL=http://localhost:3000/ bundle exec rspec
```

Run a single file:

```
RAILS_ENV=test URL=http://localhost:3000/ bundle exec rspec spec/requests/course_spec.rb
```

Run a specific example:

```
RAILS_ENV=test URL=http://localhost:3000/ bundle exec rspec spec/requests/course_spec.rb -e 'Post /add_participant'
```

## Browser tests

Browser tests, located in `spec/features`, are skipped by default. To run them, add the `--tags browser` argument to `rspec`.

## Coverage

A code coverage analysis report is generated automatically when running tests; check `coverage/index.html`.

## Running tests with a specific version of Ruby using Docker

```
docker run -it --add-host=host.docker.internal:host-gateway -w /app --entrypoint bash -v $PWD:/app:Z ruby:2.6.10
bundle install
apt update && apt install nodejs
URL=http://localhost:3000 RAILS_ENV=test bundle exec rspec spec/
```
