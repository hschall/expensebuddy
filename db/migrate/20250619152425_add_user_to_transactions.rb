class AddUserToTransactions < ActiveRecord::Migration[7.1]
  def change
    # Clean slate before adding the NOT NULL field
    Transaction.delete_all

    add_reference :transactions, :user, null: false, foreign_key: true
  end
end
  