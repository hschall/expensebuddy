class EmpresasController < ApplicationController
  require 'digest'

  def index
  Empresa.update_all_categorization_statuses_for(current_user)
  @empresas = current_user.empresas.includes(:empresa_descriptions, :category)

  # --- Filter by RFC Presence ---
  if params[:identificador_filter].present?
    if params[:identificador_filter] == "con"
      @empresas = @empresas.where.not(identificador: [nil, ""]).where.not("identificador LIKE ?", "Sin identificador%")
    elsif params[:identificador_filter] == "sin"
      @empresas = @empresas.where("identificador IS NULL OR identificador LIKE ?", "Sin identificador%")
    end
  end

  # --- Filter by Categoría ---
  if params[:categoria_filter].present?
    categoria = current_user.categories.find_by(name: params[:categoria_filter])
    @empresas = categoria ? @empresas.where(category_id: categoria.id) : Empresa.none
  end

  # --- Filter by Descripción Search ---
  if params[:search].present?
    search_term = "%#{params[:search]}%"
    adapter = ActiveRecord::Base.connection.adapter_name.downcase

    if adapter.include?("sqlite")
      @empresas = @empresas.where("LOWER(descripcion) LIKE ?", search_term.downcase)
    else
      @empresas = @empresas.where("descripcion ILIKE ?", search_term)
    end
  end

  # --- Filter by Estado (Categorizado / Sin categorizar) ---
  if params[:estado_filter].present?
    sin_categoria_id = current_user.categories.find_by(name: "Sin categoría")&.id

    @empresas = @empresas.select do |empresa|
      case params[:estado_filter]
      when "categorizado"
        if empresa.identificador.start_with?("Sin identificador")
          empresa.category_id.present? && empresa.category_id != sin_categoria_id
        else
          (empresa.consistent? && empresa.category_id.present? && empresa.category_id != sin_categoria_id) ||
          (empresa.inconsistent? && empresa.empresa_descriptions.all? { |d| d.category_id.present? && d.category_id != sin_categoria_id })
        end
      when "sin_categorizar"
        if empresa.identificador.start_with?("Sin identificador")
          empresa.category_id.nil? || empresa.category_id == sin_categoria_id
        else
          (empresa.consistent? && (empresa.category_id.nil? || empresa.category_id == sin_categoria_id)) ||
          (empresa.inconsistent? && empresa.empresa_descriptions.any? { |d| d.category_id.nil? || d.category_id == sin_categoria_id })
        end
      else
        true
      end
    end
  end

  # --- Sort ---
  @empresas = @empresas.sort_by do |e|
  case params[:sort]
  when "identificador"
    e.identificador.to_s
  when "categoria"
    e.category&.name.to_s
  when "estado"
    if e.inconsistent? && e.empresa_descriptions.any? { |d| d.category_id.nil? || d.category&.name == "Sin categoría" }
      "Incompleto"
    elsif e.consistent? && (e.category_id.nil? || e.category&.name == "Sin categoría")
      "Sin categoría"
    else
      "Categorizado"
    end
  when "descripciones"
    e.empresa_descriptions.size
  else
    e.descripcion.to_s
  end
end


  @empresas.reverse! if params[:direction] == "desc"
end





  def edit
    @empresa = current_user.empresas.find(params[:id])
    @categories = current_user.categories.order(:name)
  end

  def update
    @empresa = current_user.empresas.find(params[:id])
    if @empresa.update(empresa_params)
      redirect_to empresas_path, notice: "Empresa actualizada"
    else
      render :edit
    end
  end

  def delete_selected
    if params[:empresa_ids].present?
      current_user.empresas.where(id: params[:empresa_ids]).destroy_all
      redirect_to empresas_path, notice: "Empresas eliminadas correctamente."
    else
      redirect_to empresas_path, alert: "No seleccionaste ninguna empresa."
    end
  end

  def import_from_transactions
    existing_identifiers = current_user.empresas.pluck(:identificador)
    default_category = current_user.categories.find_or_create_by!(name: "Sin categoría")
    total_new = 0

    # --- Import Empresas with RFC ---
    new_codes = current_user.transactions
                     .where.not(company_code: [nil, ""])
                     .where.not(company_code: existing_identifiers)
                     .distinct
                     .pluck(:company_code)

    new_codes.each do |code|
      description = current_user.transactions.where(company_code: code).pluck(:description).first
      current_user.empresas.create!(
        identificador: code,
        descripcion: description.to_s.strip,
        category_id: default_category.id
      )
      total_new += 1
    end

    # --- For ALL RFC Empresas (existing and new), create EmpresaDescriptions for each unique description ---
    current_user.empresas.where.not(identificador: nil).find_each do |empresa|
      existing_descs = empresa.empresa_descriptions.pluck(:description).map(&:downcase)
      empresa_category = empresa.category_id.presence || default_category.id

      unique_descs = current_user.transactions
                          .where(company_code: empresa.identificador)
                          .where.not(description: [nil, ""])
                          .pluck(:description)
                          .map(&:strip)
                          .uniq
                          .reject { |desc| existing_descs.include?(desc.downcase) }

      unique_descs.each do |desc|
        empresa.empresa_descriptions.create!(
          description: desc,
          category_id: empresa_category
        )
      end
    end


    # --- Empresas without RFC (Sin identificador) ---
    existing_descs = current_user.empresas
                        .where("identificador LIKE ?", "Sin identificador%")
                        .pluck(:descripcion)
                        .map { |d| d.to_s.strip.downcase }

    new_descs = current_user.transactions
                    .where(company_code: [nil, ""])
                    .where.not(description: [nil, ""])
                    .pluck(:description)
                    .map(&:strip)
                    .uniq
                    .reject { |desc| existing_descs.include?(desc.downcase) }

    new_descs.each do |desc|
      unique_hash = Digest::MD5.hexdigest(desc)[0..6]
      current_user.empresas.create!(
        identificador: "Sin identificador - #{unique_hash}",
        descripcion: desc,
        category_id: default_category.id
      )
      total_new += 1
    end

    if total_new >= 1
      redirect_to empresas_path(categoria_filter: "sin"), notice: "#{total_new} nuevas empresas agregadas."
    else
      redirect_to empresas_path, notice: "No se encontraron nuevas empresas por importar."
    end
  end

  def update_all_transaction_categories
  apply_strict_transaction_categorization!
  redirect_to empresas_path, notice: "Transacciones actualizadas correctamente."
end


  def update_inline
    @empresa = current_user.empresas.find(params[:id])

    if @empresa.update(empresa_params)
      respond_to do |format|
        format.turbo_stream do
          render partial: "empresas/row", locals: { empresa: @empresa }
        end
        format.html { redirect_to empresas_path }
      end
    else
      head :unprocessable_entity
    end
  end

  def save_all
  (params[:empresas] || {}).each do |id, attrs|
    empresa = current_user.empresas.find_by(id: id)
    next unless empresa
    empresa.update(category_id: attrs[:category_id])
  end

  # Update categorization status
  current_user.empresas.find_each(&:update_categorization_status!)

  # Apply categorization
  apply_strict_transaction_categorization!

  redirect_to empresas_path(tab: params[:tab]), notice: "Cambios guardados y transacciones actualizadas."
end



  private

  def empresa_params
    params.require(:empresa).permit(:descripcion, :category_id)
  end

  def apply_strict_transaction_categorization!
  # STEP 1: Reset all transaction categories to 'Sin categoría'
  sin_categoria = current_user.categories.find_or_create_by!(name: "Sin categoría")
  current_user.transactions.update_all(category_id: sin_categoria.id)

  # STEP 2: Apply categories from EmpresaDescriptions (for transactions with RFC)
  current_user.empresas
              .where.not(identificador: nil)
              .where.not("identificador LIKE ?", "Sin identificador%")
              .includes(:empresa_descriptions)
              .find_each do |empresa|
    empresa.empresa_descriptions.where.not(category_id: nil).find_each do |desc|
      current_user.transactions
                  .where(company_code: empresa.identificador, description: desc.description)
                  .update_all(category_id: desc.category_id)
    end
  end

  # STEP 3: Apply categories from Empresas table (for transactions without RFC)
  current_user.empresas
              .where("identificador LIKE ?", "Sin identificador%")
              .where.not(category_id: nil)
              .find_each do |empresa|
    current_user.transactions
                .where(company_code: [nil, ""], description: empresa.descripcion)
                .update_all(category_id: empresa.category_id)
  end
end



end
