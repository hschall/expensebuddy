class AddAvatarFilenameToSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :settings, :avatar_filename, :string
  end
end
