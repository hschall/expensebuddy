class Category < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :restrict_with_error
  has_many :empresas, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :user_id }
end
