class SaldoHistoryGenerator
  def initialize(user)
    @user = user
    @cycle_end_day = user.setting&.cycle_end_day || 6
  end

  def generate_for_cycles(cycles)
    previous_cycle_saldo = 0

    sorted_cycles = cycles.sort

    sorted_cycles.each do |cycle_month|
      year, month = cycle_month.split("-").map(&:to_i)
      cycle_start = Date.new(year, month, @cycle_end_day + 1)
      cycle_end = (cycle_start + 1.month).change(day: @cycle_end_day)

      # Skip if cycle is not complete yet
      next if Date.today <= cycle_end

      previous_cycle_month = (cycle_start - 1.month).strftime("%Y-%m")
      previous_cycle_transactions = @user.transactions.where(cycle_month: previous_cycle_month)
      previous_positive = previous_cycle_transactions.where("amount > 0").sum(:amount).to_f
      previous_negative = previous_cycle_transactions.where("amount < 0").sum(:amount).to_f
      previous_total_balance = previous_positive + previous_negative

      current_cycle_balance_payments = @user.balance_payments.where(cycle_month: cycle_month).sum(:amount).to_f
      db_previous_saldo = @user.saldo_histories.find_by(cycle_month: previous_cycle_month)&.saldo
      previous_saldo_to_use = db_previous_saldo.nil? ? previous_cycle_saldo : db_previous_saldo

      saldo = if previous_total_balance.zero?
                0
              else
                previous_total_balance + current_cycle_balance_payments + previous_saldo_to_use
              end

      SaldoHistory.find_or_initialize_by(user: @user, cycle_month: cycle_month).update!(saldo: saldo)

      Rails.logger.info "✅ Generated saldo for #{cycle_month}: #{saldo}"

      previous_cycle_saldo = saldo
    end
  end
end
