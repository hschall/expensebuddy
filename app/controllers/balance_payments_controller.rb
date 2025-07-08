class BalancePaymentsController < ApplicationController
  def index
    if params[:cycle_month].blank?
      latest_date = current_user.balance_payments.maximum(:date)

      if latest_date.present?
        cycle_end_day = current_user.setting.cycle_end_day
        if latest_date.day > cycle_end_day
          cycle_start = latest_date.change(day: cycle_end_day + 1)
        else
          cycle_start = (latest_date - 1.month).change(day: cycle_end_day + 1)
        end

        params[:cycle_month] = cycle_start.strftime("%Y-%m")
      else
        cycle_start = Date.today.change(day: 7)
        params[:cycle_month] = cycle_start.strftime("%Y-%m")
      end
    end

    @balance_payments = filtered_balance_payments
    @total_current_payments = @balance_payments.sum(:amount)

    

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "balance_payments_table",
          partial: "balance_payments/table",
          locals: { balance_payments: @balance_payments }
        )
      end
    end
  end

  def destroy_selected
    if params[:balance_payment_ids].present?
      current_user.balance_payments.where(id: params[:balance_payment_ids]).destroy_all
      @balance_payments = filtered_balance_payments

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "balance_payments_table",
            partial: "balance_payments/table",
            locals: { balance_payments: @balance_payments }
          )
        end
        format.html { redirect_to balance_payments_path, notice: "Pagos eliminados correctamente." }
      end
    else
      redirect_to balance_payments_path, alert: "No seleccionaste ningún pago."
    end
  end

  def delete_all
    current_user.balance_payments.delete_all
    redirect_to dashboard_path, notice: "Todos los pagos de saldo han sido eliminados correctamente."
  end

  private

  def filtered_balance_payments
    records = current_user.balance_payments

    records = records.where(person: params[:person]) if params[:person].present?
    records = records.where(category: params[:category]) if params[:category].present?
    records = records.where("description ILIKE ?", "%#{params[:description]}%") if params[:description].present?

    if params[:cycle_month].present?
      selected_date = Date.strptime(params[:cycle_month], "%Y-%m")
      start_date = selected_date.change(day: 7)
      end_date = (start_date + 1.month).change(day: 6)
      records = records.where(date: start_date..end_date)
    end

    records
  end
end
