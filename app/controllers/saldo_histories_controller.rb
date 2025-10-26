class SaldoHistoriesController < ApplicationController
  def generate
	all_cycles = (current_user.transactions.distinct.pluck(:cycle_month) + current_user.balance_payments.distinct.pluck(:cycle_month))
	              .uniq.compact.sort

	previous_cycle_saldo = 0
	cycle_end_day = current_user.setting&.cycle_end_day || 6

	all_cycles.each do |cycle_month|
	  # Calculate cycle end date
	  year, month = cycle_month.split("-").map(&:to_i)
	  cycle_start = Date.new(year, month, cycle_end_day + 1)
	  cycle_end = (cycle_start + 1.month).change(day: cycle_end_day)

	  # Skip if today is before the end of the cycle
	  if Date.today <= cycle_end
	    Rails.logger.info "⏩ Skipping #{cycle_month}: cycle not finished (ends on #{cycle_end})"
	    next
	  end

	  # === Previous cycle balance
	  previous_cycle_date = Date.strptime(cycle_month, "%Y-%m") - 1.month
	  previous_cycle_month = previous_cycle_date.strftime("%Y-%m")

	  previous_cycle_transactions = current_user.transactions.where(cycle_month: previous_cycle_month)
	  previous_positive = previous_cycle_transactions.where("amount > 0").sum(:amount).to_f
	  previous_negative = previous_cycle_transactions.where("amount < 0").sum(:amount).to_f
	  previous_total_balance = previous_positive + previous_negative

	  current_cycle_balance_payments = current_user.balance_payments.where(cycle_month: cycle_month).sum(:amount).to_f
	  db_previous_saldo = current_user.saldo_histories.find_by(cycle_month: previous_cycle_month)&.saldo
	  previous_saldo_to_use = db_previous_saldo.nil? ? previous_cycle_saldo : db_previous_saldo

	  saldo = if previous_total_balance.zero?
	            0
	          else
	            previous_total_balance + current_cycle_balance_payments + previous_saldo_to_use
	          end

	  SaldoHistory.find_or_initialize_by(user: current_user, cycle_month: cycle_month).update!(saldo: saldo)

	  Rails.logger.info "✅ Generated saldo for #{cycle_month}: #{saldo}"

	  previous_cycle_saldo = saldo
	end

	redirect_to saldo_histories_path, notice: "Saldos a favor generados correctamente."

end



  def index
    @saldo_histories = current_user.saldo_histories.order(:cycle_month)
  end

  def destroy
  saldo = current_user.saldo_histories.find(params[:id])
  saldo.destroy
  redirect_to saldo_histories_path, notice: "Saldo eliminado correctamente."
end

end
