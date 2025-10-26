require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module ExpenseApp
  class Application < Rails::Application
    config.load_defaults 7.1
    config.time_zone = 'America/Mexico_City'
    config.active_record.default_timezone = :utc 

    # ✅ Ensure lib/ is loaded in all environments
    config.eager_load_paths << Rails.root.join("lib")

    # 🌐 Localization
    config.i18n.available_locales = [:en, :es]
    config.i18n.default_locale = :es
  end
end
