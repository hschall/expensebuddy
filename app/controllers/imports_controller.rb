class ImportsController < ApplicationController
  def new; end

  def create
  if params[:file].blank?
    redirect_to import_path, alert: "Por favor selecciona un archivo."
    return
  end

  begin
    parser = StatementParser.new(params[:file], current_user)
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

  # ✅ Step 1: Delete existing data for these cycles (same as before)
  adapter = ActiveRecord::Base.connection.adapter_name.downcase
  cycle_end_day = current_user.setting&.cycle_end_day || 6

  all_cycles.each do |cycle_month|
    current_user.transactions.where(cycle_month: cycle_month).delete_all


    current_user.balance_payments.where(cycle_month: cycle_month).delete_all
  end

  # ✅ Step 2: Create missing Empresas
  default_category = current_user.categories.find_or_create_by!(name: "Sin categoría")
  existing_empresas = current_user.empresas.pluck(:identificador, :descripcion)
  existing_identificadores = existing_empresas.map(&:first).compact
  existing_descripciones = existing_empresas.map(&:second).compact.map(&:downcase)

  # A. Create Empresas with RFC
  new_company_codes = transactions_data.map { |tx| tx["company_code"] }.compact.uniq - existing_identificadores
  new_company_codes.each do |code|
    description = transactions_data.find { |tx| tx["company_code"] == code }["description"]
    current_user.empresas.create!(
      identificador: code,
      descripcion: description.to_s.strip,
      category_id: default_category.id
    )
  end

  # B. Create Empresas without RFC (by description)
  no_rfc_descriptions = transactions_data
                          .select { |tx| tx["company_code"].blank? }
                          .map { |tx| tx["description"].to_s.strip }
                          .uniq
                          .reject { |desc| existing_descripciones.include?(desc.downcase) }

  no_rfc_descriptions.each do |desc|
    unique_hash = Digest::MD5.hexdigest(desc)[0..6]
    current_user.empresas.create!(
      identificador: "Sin identificador - #{unique_hash}",
      descripcion: desc,
      category_id: default_category.id
    )
  end

  # ✅ Step 3: Create EmpresaDescriptions for each empresa + description
  current_user.empresas.find_each do |empresa|
  # ✅ Skip creating descriptions for empresas without RFC
  next if empresa.identificador.start_with?("Sin identificador")

  existing_descs = empresa.empresa_descriptions.pluck(:description).map(&:downcase)
  empresa_category = empresa.category_id.presence || default_category.id

  related_descriptions = transactions_data
                           .select { |tx| tx["company_code"].to_s == empresa.identificador.to_s }
                           .map { |tx| tx["description"].to_s.strip }
                           .uniq

  related_descriptions.reject { |desc| existing_descs.include?(desc.downcase) }.each do |desc|
    empresa.empresa_descriptions.create!(
      description: desc,
      category_id: empresa_category
    )
  end
end


  # ✅ Step 4: Create Transactions
  transactions_data.each do |tx|
    matching_empresa = current_user.empresas.find_by(identificador: tx["company_code"]) ||
                       current_user.empresas.find_by(descripcion: tx["description"].to_s.strip)

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

  # ✅ Step 5: Create Balance Payments (no changes)
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
  SaldoHistoryGenerator.new(current_user).generate_for_cycles(all_cycles)
  redirect_to dashboard_path, notice: "Se actualizaron #{all_cycles.size} ciclos con un total de #{total} registros."
end



end
