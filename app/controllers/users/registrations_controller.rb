class Users::RegistrationsController < Devise::RegistrationsController
  def create
    build_resource(sign_up_params)

    if resource.save
      yield resource if block_given?
      sign_up(resource_name, resource)
      sign_in(resource) unless user_signed_in?


      # ✅ Redirect using Devise hook
      respond_with resource, location: after_sign_up_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end
end
