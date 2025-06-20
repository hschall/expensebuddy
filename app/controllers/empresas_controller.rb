class EmpresasController < ApplicationController
  require 'digest'

  def index
    @empresas = current_user.empresas.includes(:category)

    if params[:identificador_filter].present?
      if params[:identificador_filter] == "con"
        @empresas = @empresas.where.not(identificador: [nil, ""]).where.not("identificador LIKE ?", "Sin identificador%")
      elsif params[:identificador_filter] == "sin"
        @empresas = @empresas.where("identificador IS NULL OR identificador LIKE ?", "Sin identificador%")
      end
    end

    if params[:categoria_filter].present?
  if params[:categoria_filter] == "sin"
    sin_categoria = current_user.categories.find_by(name: "Sin categoría")
    @empresas = sin_categoria ? @empresas.where(category_id: sin_categoria.id) : Empresa.none
  else
    categoria = current_user.categories.find_by(name: params[:categoria_filter])
    @empresas = categoria ? @empresas.where(category_id: categoria.id) : Empresa.none
  end
end


    if params[:search].present?
      search_term = "%#{params[:search]}%"
      adapter = ActiveRecord::Base.connection.adapter_name.downcase

      if adapter.include?("sqlite")
        @empresas = @empresas.where("LOWER(descripcion) LIKE ?", search_term.downcase)
      else
        @empresas = @empresas.where("descripcion ILIKE ?", search_term)
      end
    end

    @empresas = @empresas.order(:descripcion)
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

  # Empresas with RFC
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

  # Empresas without RFC
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
    redirect_to empresas_path(categoria_filter: "sin"), notice: "#{total_new} nuevas empresas agregadas y mostradas sin categoría."
  else
    redirect_to empresas_path, notice: "No se encontraron nuevas empresas por importar."
  end
end


  def update_all_transaction_categories
    # Empresas with RFC
    current_user.empresas.where.not(identificador: nil)
                 .where.not(identificador: "Sin identificador")
                 .where.not(category_id: nil)
                 .find_each do |empresa|
      current_user.transactions.where(company_code: empresa.identificador)
                   .update_all(category_id: empresa.category_id)
    end

    # Empresas without RFC
    current_user.empresas.where("identificador LIKE ?", "Sin identificador%")
                 .where.not(category_id: nil)
                 .find_each do |empresa|
      current_user.transactions.where(company_code: [nil, ""])
                   .where(description: empresa.descripcion)
                   .update_all(category_id: empresa.category_id)
    end

    redirect_to empresas_path, notice: "Transacciones actualizadas correctamente"
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

    # Apply categories to transactions
    current_user.empresas.where.not(identificador: nil)
                 .where.not(identificador: "Sin identificador")
                 .where.not(category_id: nil)
                 .find_each do |empresa|
      current_user.transactions.where(company_code: empresa.identificador)
                   .update_all(category_id: empresa.category_id)
    end

    current_user.empresas.where("identificador LIKE ?", "Sin identificador%")
                 .where.not(category_id: nil)
                 .find_each do |empresa|
      current_user.transactions.where(company_code: [nil, ""])
                   .where(description: empresa.descripcion)
                   .update_all(category_id: empresa.category_id)
    end

    redirect_to empresas_path(tab: params[:tab]), notice: "Cambios guardados y transacciones actualizadas."
  end

  private

  def empresa_params
    params.require(:empresa).permit(:descripcion, :category_id)
  end
end
