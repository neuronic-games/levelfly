Oncapus::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Load environment variables for development
  config.before_configuration do
    aws_env_file = Rails.root.join('config', 'application.yml').to_s
    if File.exist?(aws_env_file)
      puts "Environment variables loaded from #{aws_env_file}"
      YAML.load_file(aws_env_file).each do |k, v|
        ENV[k.to_s] = v
        puts "#{k} = #{v}"
      end
    end
  end

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  config.eager_load = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

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
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp

  # Used for password reminder emails
  config.action_mailer.default_url_options = { host: ENV.fetch('MAILER_DEFAULT_URL', nil) }

  ActionMailer::Base.smtp_settings = {
    address: 'localhost',
    port: 1025,
    domain: 'localhost'
  }

  ActionMailer::Base.default content_type: 'text/html'

  Pusher.url = ENV.fetch('PUSHER_URL', nil)

  # oink
  config.middleware.use(Oink::Middleware, logger: Hodel3000CompliantLogger.new(STDOUT))
end
