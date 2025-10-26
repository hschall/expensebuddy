class CreateEmpresas < ActiveRecord::Migration[7.1]
  def change
    create_table :empresas do |t|
      t.string :identificador
      t.string :descripcion
      t.integer :category_id

      t.timestamps
    end
  end
end
