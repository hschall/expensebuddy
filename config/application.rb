require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module ExpenseApp
  class Application < Rails::Application
    
    config.load_defaults 7.1
    config.time_zone = 'America/Mexico_City' 
    config.autoload_lib(ignore: %w(assets tasks))
    config.i18n.default_locale = :es
  end
end
