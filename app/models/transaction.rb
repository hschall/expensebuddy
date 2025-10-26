class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true

  enum transaction_type: { income: "income", expense: "expense" }

  validates :date, :description, :amount, :transaction_type, :person, presence: true

  def self.apply_categorization_for_empresa(empresa)
  return unless empresa.present?

  # 1. Apply categories from empresa_descriptions (for RFC-type empresas)
  if empresa.identificador.present? && !empresa.identificador.start_with?("Sin identificador")
    empresa.empresa_descriptions.where.not(category_id: nil).find_each do |desc|
      empresa.user.transactions
        .where(company_code: empresa.identificador, description: desc.description)
        .update_all(category_id: desc.category_id)
    end
  else
    # 2. Apply categories from empresa directly (for 'Sin identificador' type)
    empresa.user.transactions
      .where(company_code: empresa.identificador)
      .update_all(category_id: empresa.category_id)
  end
end

end
