class Empresa < ApplicationRecord
  belongs_to :category, optional: true

  validates :descripcion, :identificador, presence: true, uniqueness: true
end
