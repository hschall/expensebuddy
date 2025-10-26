class EmpresaDescription < ApplicationRecord
  belongs_to :empresa
  belongs_to :category, optional: true

  validates :description, presence: true, uniqueness: { scope: :empresa_id }
end
