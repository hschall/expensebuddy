class AddUserToBalancePayments < ActiveRecord::Migration[7.1]
  def change
    # Clean slate before adding the NOT NULL field
    BalancePayment.delete_all

    add_reference :balance_payments, :user, null: false, foreign_key: true
  end
end
