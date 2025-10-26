class AddCategorizationStatusToEmpresas < ActiveRecord::Migration[7.0]
  def change
    add_column :empresas, :categorization_status, :string, default: "consistent", null: false
  end
end
