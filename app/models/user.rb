class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :transactions
  has_many :balance_payments
  has_one :setting
  has_many :empresas
  has_many :categories
  has_many :saldo_histories, dependent: :destroy

  after_create :create_default_setting #:create_default_categories, 

  private

  #def create_default_categories
  #  %w[Sin\ categoría Amazon].each do |cat|
  #    categories.create(name: cat)
  #  end
  #end

  def create_default_setting
    create_setting
  end
end
