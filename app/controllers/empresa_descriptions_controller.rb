class EmpresaDescriptionsController < ApplicationController
  before_action :set_empresa

  def index
    @empresa_descriptions = @empresa.empresa_descriptions.includes(:category).order(:description)
    @categories = current_user.categories.order(:name)
  end

  def update_all
  @empresa = current_user.empresas.find(params[:empresa_id])
  @categories = current_user.categories.order(:name)

  updated = 0

  params[:descriptions]&.each do |id, attrs|
    desc = @empresa.empresa_descriptions.find_by(id: id)
    next unless desc

    if desc.update(category_id: attrs[:category_id])
      updated += 1
    end
  end

  # Update empresa consistency
  @empresa.update_categorization_status!

  # Apply categorization to relevant transactions
  Transaction.apply_categorization_for_empresa(@empresa)

  # ✅ Redirect to Empresas index page
  redirect_to empresas_path, notice: "Descripciones actualizadas y transacciones sincronizadas."
end




  private

  def set_empresa
    @empresa = current_user.empresas.find(params[:empresa_id])
  end
end
