class SettingsController < ApplicationController

  def edit
    @setting = current_user.setting || current_user.build_setting
    @setting.save if @setting.new_record?
  end

  def update
  @setting = current_user.setting || current_user.build_setting
  @setting.save if @setting.new_record?

  if @setting.update(setting_params)
    redirect_to dashboard_path, notice: "Configuración actualizada."
  else
    render :edit
  end
end


  def delete_all_records
    current_user.transactions.destroy_all
    current_user.balance_payments.destroy_all
    redirect_to dashboard_path, notice: "Todos los registros de tu usuario fueron eliminados correctamente."
  end

  private

  def setting_params
    params.require(:setting).permit(:nombre, :cycle_end_day, :avatar_filename)
  end

end
