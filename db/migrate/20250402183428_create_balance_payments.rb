class CreateBalancePayments < ActiveRecord::Migration[7.1]
  def change
    create_table :balance_payments do |t|
      t.date :date
      t.decimal :amount
      t.string :description
      t.string :category
      t.string :cycle_month

      t.timestamps
    end
  end
end
