Oncapus::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # TODO: Consider removing this; even development settings should probably be loaded from env

  # Do not eager load code on boot.
  config.eager_load = false

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Enable server timing
  config.server_timing = true

  config.eager_load = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  # config.assets.debug = true

  # Activate observers that should always be running
  config.active_record.observers = :participant_observer

  # Commented for development because causing error on local
  # config.logger = Logger.new(STDOUT)
  # config.log_level = :debug #:warn

  # Expands the lines which load the assets
  config.assets.debug = true

  Pusher.url = ENV.fetch('PUSHER_URL', 'https://example.com')
end
