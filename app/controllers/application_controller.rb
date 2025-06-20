# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  def after_sign_up_path_for(resource)
  puts "AFTER SIGN UP PATH HIT!" # just for confirmation
  edit_settings_path
end


  def after_sign_in_path_for(resource)
    setting = resource.setting

    if setting.nil? || setting.cycle_end_day.blank?
      edit_settings_path
    else
      dashboard_path
    end
  end

  def after_update_path_for(resource)
    dashboard_path
  end

  def after_inactive_sign_up_path_for(resource)
    edit_settings_path
  end
end
