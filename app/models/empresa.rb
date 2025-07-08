class Empresa < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true

  has_many :empresa_descriptions, dependent: :destroy

  enum categorization_status: { consistent: "consistent", inconsistent: "inconsistent" }

  validates :descripcion, :identificador, presence: true
  validates :descripcion, uniqueness: { scope: :user_id }
  validates :identificador, uniqueness: { scope: :user_id }

  after_update :cascade_category_to_descriptions, if: :saved_change_to_category_id?
  after_update :reset_category_if_inconsistent

  def update_categorization_status!
    child_categories = empresa_descriptions.pluck(:category_id).uniq.compact

    if child_categories.empty?
      update!(categorization_status: "consistent")
    elsif child_categories.size == 1 && child_categories.first == category_id
      update!(categorization_status: "consistent")
    else
      update!(categorization_status: "inconsistent")
    end
  end

  def self.update_all_categorization_statuses_for(user)
    user.empresas.find_each do |empresa|
      empresa.update_categorization_status!
    end
  end

  private

  def cascade_category_to_descriptions
    return if identificador.start_with?("Sin identificador")  # ❗ Skip for "Sin identificador" empresas

    empresa_descriptions.update_all(category_id: self.category_id)
  end

  def reset_category_if_inconsistent
    return unless saved_change_to_categorization_status?
    return unless categorization_status == "inconsistent"

    # ❌ Don't reset category for empresas without RFC
    return if identificador.start_with?("Sin identificador")

    sin_categoria = user.categories.find_or_create_by(name: "Sin categoría")
    update_column(:category_id, sin_categoria.id) unless category_id == sin_categoria.id
  end

end
