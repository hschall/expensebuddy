class Category < ApplicationRecord
  has_many :transactions
  has_many :empresas

  validates :name, presence: true, uniqueness: true
end
