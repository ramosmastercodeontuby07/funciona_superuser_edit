class AddLinuxUsernameToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :linux_username, :string
    add_index :users, :linux_username
  end
end
