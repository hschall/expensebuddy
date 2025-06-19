class AddCountryToBalancePayments < ActiveRecord::Migration[7.1]
  def change
    add_column :balance_payments, :country, :string
  end
end
