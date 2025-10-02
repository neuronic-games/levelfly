# Testing

Run all tests:

```shell
bundle exec rspec
```

Run a single file:

```shell
bundle exec rspec spec/requests/course_spec.rb
```

Run a specific example:

```shell
bundle exec rspec spec/requests/course_spec.rb -e 'Post /add_participant'
```

## Test conventions

### HTTP tests ("request specs")

Most tests are implemented as "request specs"; [quoth the `README` for `rails/spec`][request-specs]:

> When writing them, try to answer the question, "For a given HTTP request (verb + path + parameters), what HTTP response should the application return?"

See the existing tests in `spec/requests` for examples.

To add a test for a new HTTP endpoint, create a `context` for each HTTP verb it supports, using `let` to define `url` using `url_for`, and the request `params` which should be sent with requests:

```ruby
  context 'when GET /support' do
    let(:url) { url_for(controller: 'gamecenter', action: :support) }
    let(:params) { { game_id: game_one.id } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end
  end
```

For endpoints which have multiple different behaviour depending on the value of `params`, you can vary `params` between blocks using one of these methods, depending on how many changes need to be made:

* If `params` is completely different between blocks (e.g. `filter=A` vs `filter=B`, with no other parameters), don't use `let` and just set `params: { filter: 'A' }` in the call to `get` or `post`.
* If `params` is mostly the same between blocks (e.g. only one parameter needs to change), use `let(:params)`, and tweak the `params` per-block using `params: params.merge!({ filter: B })`.
* If you need different sets of parameters for different blocks, but fewer than one set of parameters per block, you can use `let` multiple times, e.g. establishing `params` and `params_archived`.

### Browser tests ("feature specs")

Browser tests, located in `spec/features`, are skipped by default. To run them, add the `--tag browser` argument to `rspec`.

These take significantly longer to run than other kinds of tests, and require a working web browser and webdriver.

### Unit tests ("model specs")

## Coverage

A code coverage analysis report is generated automatically when running tests; check `coverage/index.html`.

## Running tests with a specific version of Ruby using Docker

```shell
docker run -it --add-host=host.docker.internal:host-gateway -w /app --entrypoint bash -v $PWD:/app:Z ruby:2.6.10
bundle install
apt update && apt install nodejs
URL=http://localhost:3000 RAILS_ENV=test bundle exec rspec spec/
```

[request-specs]: https://github.com/rspec/rspec-rails?tab=readme-ov-file#request-specs
