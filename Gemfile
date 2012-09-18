source 'http://rubygems.org'

gem 'rails', '3.1.1'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

# We don't really need sqlite for the project, but if we don't add it
# the "RAILS_ENV=production bundle exec rake assets:precompile" commands errors.
gem 'sqlite3'

# Database drivers for different environments
group :production do
  gem 'pg'
end

group :development, :test do
  gem 'mysql'
end

gem 'rake' , '>= 0.9.2'
gem 'json'
gem 'devise'
gem 'taps', '>= 0.3.23'
gem 'acts-as-taggable-on', '~>2.2.0'
gem 'rails_autolink'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.1.4'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'
gem 'aws-s3', :require => 'aws/s3'

gem 'paperclip', '2.4.5'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug'

