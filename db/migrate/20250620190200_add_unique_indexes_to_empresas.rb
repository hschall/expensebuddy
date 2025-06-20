class AddUniqueIndexesToEmpresas < ActiveRecord::Migration[7.0]
  def change
    add_index :empresas, [:user_id, :descripcion], unique: true
    add_index :empresas, [:user_id, :identificador], unique: true
  end
end
