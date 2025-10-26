class CreateEmpresaDescriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :empresa_descriptions do |t|
      t.references :empresa, null: false, foreign_key: true
      t.string :description, null: false
      t.references :category, foreign_key: true
      t.timestamps
    end

    add_index :empresa_descriptions, [:empresa_id, :description], unique: true
  end
end
