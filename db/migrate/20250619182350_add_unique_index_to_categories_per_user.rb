class AddUniqueIndexToCategoriesPerUser < ActiveRecord::Migration[7.1]
  def change
    # Remove global name index if it exists
    remove_index :categories, :name if index_exists?(:categories, :name)

    # Add composite unique index for [user_id, name]
    add_index :categories, [:user_id, :name], unique: true
  end
end
