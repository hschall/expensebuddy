class AddNombreToSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :settings, :nombre, :string
  end
end
