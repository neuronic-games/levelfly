require 'pusher'
require 'activerecord-nulldb-adapter'

Oncapus::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  config.eager_load = true

  # Code is not reloaded between requests
  config.cache_classes = false

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  # config.serve_static_assets = true
  config.serve_static_files = true

  # Set logging verbosity
  config.log_level = :info

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Activate observers that should always be running
  # config.active_record.observers = :participant_observer

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = false

  # See everything in the log (default is :info)
  # config.logger = Logger.new(STDOUT)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )
  config.assets.precompile += %w[vendor.js]

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Used for password reminder emails
  config.action_mailer.default_url_options = { host: ENV.fetch('MAILER_DEFAULT_URL', nil) }

  Pusher.url = ENV.fetch('PUSHER_URL', nil)

  ActionMailer::Base.smtp_settings = {
    address: ENV.fetch('SMTP_HOST', nil),
    port: ENV.fetch('SMTP_POST', nil),
    domain: ENV.fetch('SMTP_DOMAIN', nil),
    user_name: ENV.fetch('SMTP_USERNAME', nil),
    password: ENV.fetch('SMTP_PASSWORD', nil),
    authentication: 'plain'
  }

  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.default content_type: 'text/html'

  if ENV.fetch('COMPILE_ASSETS', nil)
    NullDB.configure do |ndb|
      def ndb.project_root
        Oncapus.root
      end
    end
  end
end
