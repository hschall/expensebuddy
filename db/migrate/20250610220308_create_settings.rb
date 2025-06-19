class CreateSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :settings do |t|
      t.integer :cycle_end_day

      t.timestamps
    end
  end
end
