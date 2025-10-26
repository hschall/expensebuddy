class AddUserToSettings < ActiveRecord::Migration[7.1]
  def change
    # Clean slate before adding the NOT NULL field
    Setting.delete_all

    add_reference :settings, :user, null: false, foreign_key: true
  end
end
