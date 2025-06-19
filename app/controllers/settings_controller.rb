# app/controllers/settings_controller.rb
class SettingsController < ApplicationController
  def edit
    @setting = Setting.first_or_create
  end

  def update
    @setting = Setting.first
    if @setting.update(setting_params)
      redirect_to edit_settings_path, notice: "Configuración actualizada."
    else
      render :edit
    end
  end

  def delete_all_records
  Transaction.delete_all
  BalancePayment.delete_all
  redirect_to dashboard_path, notice: "Todos los registros fueron eliminados correctamente."
end


  private

  def setting_params
    params.require(:setting).permit(:cycle_end_day)
  end
end
