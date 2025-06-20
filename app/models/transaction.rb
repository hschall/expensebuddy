class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true

  enum transaction_type: { income: "income", expense: "expense" }

  validates :date, :description, :amount, :transaction_type, :person, presence: true
end
