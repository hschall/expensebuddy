class Empresa < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true

  validates :descripcion, :identificador, presence: true
  validates :descripcion, uniqueness: { scope: :user_id }
  validates :identificador, uniqueness: { scope: :user_id }
end
