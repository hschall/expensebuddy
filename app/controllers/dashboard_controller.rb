class DashboardController < ApplicationController
  def index
    # === Cycle month setup ===
    if params[:cycle_month].blank?
      latest_date = current_user.transactions.maximum(:date)

      if latest_date.present?
        cycle_end_day = current_user.setting&.cycle_end_day || 6
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

    # === Transactions base scope ===
    transactions = current_user.transactions
    transactions = transactions.where(cycle_month: params[:cycle_month]) if params[:cycle_month].present?
    transactions = transactions.where(person: params[:person]) if params[:person].present? && params[:person] != "Todos"
    transactions = transactions.where("description LIKE ?", "%#{params[:description]}%") if params[:description].present?
    transactions = transactions.where(category_id: params[:category_id]) if params[:category_id].present?

    @transactions = transactions

    # === Cycle date ranges and labels ===
    if params[:cycle_month].present?
      year, month = params[:cycle_month].split("-").map(&:to_i)
      cycle_end_day = current_user.setting&.cycle_end_day || 6
      cycle_start_day = cycle_end_day + 1

      @cycle_start_date = Date.new(year, month, cycle_start_day)
      @cycle_end_date = (@cycle_start_date + 1.month).change(day: cycle_end_day)
      @payment_due_date = Holiday.adjust_to_business_day(@cycle_end_date + 13)

      @formatted_cycle_range = "Para el periodo del #{@cycle_start_date.day} de #{I18n.l(@cycle_start_date, format: '%B', locale: :es)} al #{@cycle_end_date.day} de #{I18n.l(@cycle_end_date, format: '%B', locale: :es)}"
    end

    # === Totals ===
    @total_expenses = @transactions.expense.sum(:amount)
    @total_income = @transactions.income.sum(:amount)
    @net_savings = @total_income - @total_expenses
    @monthly_avg_expense = @total_expenses / 12.0
    @total_positive_amount = @transactions.where("amount > 0").sum(:amount)
    @total_negative_amount = @transactions.where("amount < 0").sum(:amount)
    @total_balance = @total_positive_amount + @total_negative_amount

    # === Category summaries ===
    filtered_categories = params[:category_filter].present? ? Array(params[:category_filter]) : current_user.categories.pluck(:name)
    @selected_categories = filtered_categories

    @category_distribution = @transactions
      .joins(:category)
      .where(categories: { name: filtered_categories })
      .group("categories.name")
      .sum(:amount)

    @category_sorted_data = @category_distribution.sort_by { |_category, amount| -amount }.to_h

    @spending_by_category = @transactions.joins(:category).group("categories.name").sum(:amount)
    @spending_by_person = @transactions.group(:person).sum(:amount)

    @category_colors = [
      '#4f98bf', '#f28b82', '#81c995', '#fbbc04', '#a7b0d4',
      '#c6e2ff', '#ffd6a5', '#bdb2ff', '#ffadad', '#a0c4ff'
    ]

    # === Monthly bar chart (7th–6th cycles) ===
    current_year = Date.today.year
    @monthly_labels = []
    @monthly_expenses = []

    (1..12).each do |month|
      start_date = Date.new(current_year, month, 7)
      end_date = (start_date + 1.month).change(day: 6)

      scope = current_user.transactions.where(date: start_date..end_date)
      scope = scope.where(person: params[:person]) if params[:person].present? && params[:person] != "Todos"

      @monthly_labels << start_date.strftime("%b %Y")
      @monthly_expenses << (scope.sum(:amount).to_f || 0)
    end

    # 1. Previous cycle calculation
Rails.logger.info "🔍 Current cycle_month param: #{params[:cycle_month]}"
previous_cycle_date = Date.strptime(params[:cycle_month], "%Y-%m") - 1.month
previous_cycle_month = previous_cycle_date.strftime("%Y-%m")
Rails.logger.info "🔍 Previous cycle_month: #{previous_cycle_month}"

# 2. Previous total balance
previous_cycle_transactions = current_user.transactions.where(cycle_month: previous_cycle_month)
previous_positive = previous_cycle_transactions.where("amount > 0").sum(:amount).to_f
previous_negative = previous_cycle_transactions.where("amount < 0").sum(:amount).to_f
previous_total_balance = previous_positive + previous_negative

Rails.logger.info "🔍 Previous cycle totals — Positive: #{previous_positive}, Negative: #{previous_negative}, Total: #{previous_total_balance}"

# 3. Current balance payments
current_cycle_balance_payments = current_user.balance_payments.where(cycle_month: params[:cycle_month]).sum(:amount).to_f
Rails.logger.info "🔍 Current cycle balance payments total: #{current_cycle_balance_payments}"

# 4. Final saldo a favor
@saldo_a_favor = previous_total_balance - current_cycle_balance_payments
Rails.logger.info "✅ Saldo a favor: #{@saldo_a_favor}"


    # === ✅ Saldo a Favor using SaldoHistories ===

# 1. Find saldo from the SaldoHistory table for the current cycle_month
@saldo_a_favor = current_user.saldo_histories.find_by(cycle_month: params[:cycle_month])&.saldo || 0

# 2. Final total = total_balance + saldo a favor
@total_final = @total_balance + @saldo_a_favor


  end


end
