require 'holidays'

# Load your custom YAML if using one
custom_yaml_path = Rails.root.join("config", "holidays", "mexico.yaml")
Holidays.load_custom(custom_yaml_path) if File.exist?(custom_yaml_path)
