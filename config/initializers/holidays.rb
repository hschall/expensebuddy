# config/initializers/holidays.rb

require 'holidays'

yaml_file = Rails.root.join('config/holidays/mexico.yaml')
Holidays.load_custom(yaml_file) if File.exist?(yaml_file)
