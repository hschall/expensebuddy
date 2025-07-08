class SaldoHistory < ApplicationRecord
  belongs_to :user

  validates :cycle_month, presence: true
end
