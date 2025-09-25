ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# FIXME: Temporary workaround for Ruby 3.2 compatibility for gems, see https://idogawa.dev/p/2023/01/file-exists-ruby.html
require 'file_exists'

require 'logger' # Work around removal of this require in ActiveSupport, https://stackoverflow.com/a/79385484
