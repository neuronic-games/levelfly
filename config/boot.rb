ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

require "logger"  # Work around removal of this require in ActiveSupport, https://stackoverflow.com/a/79385484
