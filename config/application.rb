require File.expand_path('boot', __dir__)

require 'rails/all'
require 'csv'
require 'sprockets/railtie'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(assets: %w[development test]))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Oncapus
  class Application < Rails::Application
    config.load_defaults '7.0'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W[#{config.root}/lib]

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    config.active_record.observers = :participant_observer, :task_observer, :category_observer, :outcome_task_observer
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true

    # This allows assets to be precompiled without connecting to a production database
    # Use this command: RAILS_ENV=production bundle exec rake assets:precompile
    config.assets.initialize_on_precompile = false

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.grade_palette = true

    # TODO: Add optional: true to all belongs_to where needed, https://stackoverflow.com/a/45673178/14269772
    Rails.application.config.active_record.belongs_to_required_by_default = false

    # Load Paperclip S3 details from env
    config.paperclip_defaults = {
      storage: :s3,
      s3_protocol: ENV.fetch('S3_PROTOCOL', nil),
      s3_permissions: 'private',
      s3_region: ENV.fetch('S3_REGION', 'us-east-1'),
      s3_credentials: {
        bucket: ENV.fetch('S3_bucket', 'levelfly'),
        access_key_id: ENV.fetch('S3_ACCESS_KEY_ID', nil),
        secret_access_key: ENV.fetch('S3_ACCESS_KEY_ID', nil)
      },
      s3_host_name: ENV.fetch('S3_HOST_NAME', nil),
      s3_options: {
        endpoint: ENV.fetch('S3_ENDPOINT', nil),
        force_path_style: ENV.fetch('S3_FORCE_PATH_STYLE', false)
      },
      url: ':s3_path_url'
    }
  end
end
