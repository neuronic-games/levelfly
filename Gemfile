source 'https://rubygems.org'

ruby '3.3.9'

gem 'activesupport'
gem 'acts-as-taggable-on'
gem 'aws-sdk'
gem 'deep_cloneable'
gem 'delayed_job_active_record'
gem 'devise'
gem 'em-http-request'
gem 'jquery-rails'
gem 'json', '>= 1.8.5'
gem 'matrix', '~> 0.4.3'
gem 'newrelic_rpm'
gem 'nokogiri'
gem 'pg'
gem 'pusher'
gem 'rails', '~> 7.2.0'
gem 'rails_autolink'
gem 'rails-observers'
gem 'rake', '>= 0.9.2'
gem 'remotipart', '~> 1.2'
gem 'taps', '>= 0.3.23'
gem 'thin', '1.8.0'
gem 'useragent', '0.16.7'
gem 'webrick', '~> 1.9'
gem 'will_paginate', '~> 3.0'

# NOTE: Pinned to work around upgrade issues
gem 'ffi', '< 1.17.0'

# NOTE: Paperclip is deprecated, temporarily use fork to work around missing URI::escape on Ruby >= 3.0.0
gem 'kt-paperclip'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'activerecord-nulldb-adapter', '~> 1.1'
  gem 'coffee-rails'
  gem 'sass', '~> 3.2.5'
  gem 'sass-rails'
  gem 'uglifier', '>= 1.0.3'
end

gem 'rails_12factor', group: :production

group :development do
  gem 'rubocop'
  gem 'rubocop-rspec'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner', '~> 2.1'
  gem 'factory_bot_rails', '~> 4.9'
  gem 'faker', '~> 2.22'
  gem 'pusher-fake', '~> 2.2'
  gem 'rails-controller-testing', '~> 1.0'
  gem 'rspec', '~> 3.13'
  gem 'rspec-rails'
  gem 'selenium-webdriver', '~> 3.142'
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'pry'
  gem 'pry-byebug'
end

gem "file_exists", "~> 0.2.0"
