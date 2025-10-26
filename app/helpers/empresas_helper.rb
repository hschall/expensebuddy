module EmpresasHelper
  def empresas_with_pending_categories?(user)
    sin_categoria_id = user.categories.find_by(name: "Sin categoría")&.id

    user.empresas.any? do |empresa|
      if empresa.identificador.start_with?("Sin identificador")
        empresa.category_id.nil? || empresa.category_id == sin_categoria_id
      elsif empresa.consistent?
        empresa.category_id.nil? || empresa.category_id == sin_categoria_id
      elsif empresa.inconsistent?
        empresa.empresa_descriptions.any? { |d| d.category_id.nil? || d.category&.id == sin_categoria_id }
      else
        false
      end
    end
  end
end
