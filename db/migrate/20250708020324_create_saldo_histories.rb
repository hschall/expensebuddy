class CreateSaldoHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :saldo_histories do |t|
      t.string :cycle_month
      t.decimal :saldo
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
