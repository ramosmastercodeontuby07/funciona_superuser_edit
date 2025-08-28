class AddFingerprintToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :fingerprint_template, :text   unless column_exists?(:users, :fingerprint_template)
    add_column :users, :fingerprint_device,    :string unless column_exists?(:users, :fingerprint_device)
  end
end
