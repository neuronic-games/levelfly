# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

APP_VERSION = '1.9.7'

# Initialize the rails application
Oncapus::Application.initialize!

# TODO: Consider switching to this, which is recommended every time we run `rails app:update`:
# Rails.application.initialize
