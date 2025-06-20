class ImportsController < ApplicationController
  def new; end

  def create
  if params[:file].blank?
    redirect_to import_path, alert: "Por favor selecciona un archivo."
    return
  end

  begin
    parser = StatementParser.new(params[:file])
    result = parser.parse

    @transactions_preview = result[:transactions]
    @balance_payments_preview = result[:balance_payments]

    # Detect all unique cycles in the uploaded file
    @all_cycles = (
      @transactions_preview.map { |tx| tx[:cycle_month] } +
      @balance_payments_preview.map { |bp| bp[:cycle_month] }
    ).uniq.compact.sort.reverse

    # Legacy support: assign latest cycle to @cycle_month
    @cycle_month = @all_cycles.first

    # Maintain legacy boolean for showing alert + checkbox
    @existing_cycle = @cycle_month.present? && (
    current_user.transactions.exists?(cycle_month: @cycle_month) ||
    current_user.balance_payments.exists?(cycle_month: @cycle_month)
    )

    # New array with *all* existing cycles (optional future use)
    @existing_cycles = @all_cycles.select do |cycle|
    current_user.transactions.exists?(cycle_month: cycle) || current_user.balance_payments.exists?(cycle_month: cycle)
  end

    render :create
  rescue StandardError => e
    Rails.logger.error("Import error: #{e.message}")
    redirect_to import_path, alert: "El archivo no pudo ser procesado. Verifica el formato e intenta nuevamente."
  end
end




def batch_create
  transactions_data = JSON.parse(params[:transactions])
  payments_data = JSON.parse(params[:balance_payments])

  all_cycles = (transactions_data.map { |tx| tx["cycle_month"] } +
                payments_data.map { |bp| bp["cycle_month"] }).uniq.compact

  adapter = ActiveRecord::Base.connection.adapter_name.downcase
  cycle_end_day = current_user.setting&.cycle_end_day || 6

  all_cycles.each do |cycle_month|
    if adapter.include?("sqlite")
  year, month = cycle_month.split("-").map(&:to_i)
  cycle_start = Date.new(year, month, cycle_end_day + 1)
  cycle_end = (cycle_start + 1.month) - 1

  # Old version (risk of deleting everyone’s data)
  # current_user.transactions.where(date: cycle_start..cycle_end).delete_all

  # ✅ Correct version: only delete current_user's records in that date range
  current_user.transactions.where(date: cycle_start..cycle_end).delete_all
else
  # ✅ Only delete current_user's transactions in that cycle
  current_user.transactions.where("to_char(date, 'YYYY-MM') = ?", cycle_month).delete_all
end

# ✅ Same for balance payments
current_user.balance_payments.where(cycle_month: cycle_month).delete_all

  end

  # Ensure user-scoped fallback category
  default_category = current_user.categories.find_or_create_by!(name: "Sin categoría")

transactions_data.each do |tx|
  matching_empresa =
    if tx["company_code"].present?
      current_user.empresas.find_by(identificador: tx["company_code"])
    else
      current_user.empresas.where("identificador LIKE ?", "Sin identificador%")
                   .find_by(descripcion: tx["description"])
    end

  # Only assign category if it belongs to current user
  category = matching_empresa&.category
category = nil unless category&.user_id == current_user.id
category ||= default_category

current_user.transactions.create!(
  date: tx["date"],
  description: tx["description"],
  person: tx["person"],
  amount: tx["amount"],
  company_code: tx["company_code"],
  country: tx["country"],
  transaction_type: tx["amount"].to_f < 0 ? "income" : "expense",
  category: category,
  cycle_month: tx["cycle_month"]
)

end


  payments_data.each do |payment|
    current_user.balance_payments.create!(
      date: payment["date"],
      description: payment["description"],
      person: payment["person"],
      amount: payment["amount"],
      country: payment["country"],
      category: payment["category"],
      cycle_month: payment["cycle_month"]
    )
  end

  total = transactions_data.count + payments_data.count
  redirect_to dashboard_path, notice: "Se actualizaron #{all_cycles.size} ciclos con un total de #{total} registros."
end







end
