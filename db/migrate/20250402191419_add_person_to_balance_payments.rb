class AddPersonToBalancePayments < ActiveRecord::Migration[7.1]
  def change
    add_column :balance_payments, :person, :string
  end
end
