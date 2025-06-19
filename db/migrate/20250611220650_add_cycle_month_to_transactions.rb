class AddCycleMonthToTransactions < ActiveRecord::Migration[7.1]
  def change
    add_column :transactions, :cycle_month, :string
  end
end
