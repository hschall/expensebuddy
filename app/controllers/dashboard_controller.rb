class DashboardController < ApplicationController
  def index
    # Default cycle month logic
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

    # Base scope
    transactions = current_user.transactions
    if params[:cycle_month].present?
      transactions = transactions.where(cycle_month: params[:cycle_month])
    end

    # Apply filters for table/dashboard cards
    transactions = transactions.where(person: params[:person]) if params[:person].present? && params[:person] != "Todos"
    transactions = transactions.where("description LIKE ?", "%#{params[:description]}%") if params[:description].present?
    transactions = transactions.where(category_id: params[:category_id]) if params[:category_id].present?

    if params[:cycle_month].present?
      year, month = params[:cycle_month].split("-").map(&:to_i)
      cycle_end_day = current_user.setting&.cycle_end_day || 6

      @cycle_end_date = Date.new(year, month, cycle_end_day)
      @cycle_start_date = (@cycle_end_date + 1.month).change(day: cycle_end_day + 1)
      @payment_due_date = Holiday.adjust_to_business_day(@cycle_end_date + 13)

      @formatted_cycle_range = "Para el periodo del #{@cycle_start_date.day} de #{I18n.l(@cycle_end_date, format: '%B', locale: :es).capitalize} al #{@cycle_end_date.day} de #{I18n.l(@cycle_start_date, format: '%B', locale: :es).capitalize}"
    end

    @transactions = transactions

    # Totals
    @total_expenses = @transactions.expense.sum(:amount)
    @total_income = @transactions.income.sum(:amount)
    @net_savings = @total_income - @total_expenses
    @monthly_avg_expense = @total_expenses / 12.0
    @total_positive_amount = @transactions.where("amount > 0").sum(:amount)
    @total_negative_amount = @transactions.where("amount < 0").sum(:amount)
    @total_balance = @total_positive_amount + @total_negative_amount

    # === Category Filter for chart + table ===
    filtered_categories = if params[:category_filter].present?
                            Array(params[:category_filter])
                          else
                            current_user.categories.pluck(:name)
                          end
    @selected_categories = filtered_categories

    @category_distribution = @transactions
      .joins(:category)
      .where(categories: { name: filtered_categories })
      .group("categories.name")
      .sum(:amount)

    @category_sorted_data = @category_distribution.sort_by { |_category, amount| -amount }.to_h

    @category_colors = [
      '#4f98bf', '#f28b82', '#81c995', '#fbbc04', '#a7b0d4',
      '#c6e2ff', '#ffd6a5', '#bdb2ff', '#ffadad', '#a0c4ff'
    ]

    @spending_by_category = @transactions.joins(:category).group("categories.name").sum(:amount)
    @spending_by_person = @transactions.group(:person).sum(:amount)

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
  end
end
