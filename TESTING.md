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

## Coverage

A code coverage analysis report is generated automatically when running tests; check `coverage/index.html`.
