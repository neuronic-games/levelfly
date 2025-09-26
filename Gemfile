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
gem "rexml", "~> 3.4"

# NOTE: Pinned to work around upgrade issues
gem 'ffi', '< 1.17.0'

# TODO: Paperclip is deprecated, we're temporarily using this fork to work around missing URI::escape on Ruby >= 3.0.0, but we should switch to ActiveStorage
gem 'kt-paperclip'

# TODO: Drop this once all dependent gems are updated far enough to not rely on it
gem 'file_exists', '~> 0.2.0'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'activerecord-nulldb-adapter'
  gem 'coffee-rails'
  gem 'sass', '~> 3.2.5'
  gem 'sass-rails'
  gem 'uglifier', '>= 1.0.3'
end

gem 'rails_12factor', group: :production

group :development do
  gem 'rubocop'
  gem 'rubocop-capybara', '~> 2.22'
  gem 'rubocop-factory_bot', '~> 2.27'
  gem 'rubocop-rails', '~> 2.33'
  gem 'rubocop-rake', '~> 0.7.1'
  gem 'rubocop-rspec'
  gem 'rubocop-rspec_rails', '~> 2.31'
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
