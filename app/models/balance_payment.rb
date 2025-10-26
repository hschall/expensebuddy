class BalancePayment < ApplicationRecord
  belongs_to :user

  validates :date, :amount, :description, :category, :cycle_month, :person, presence: true
end
