class AddSecretCodeToUsers < ActiveRecord::Migration[7.0]
    def change
      add_column :users, :secret_code, :string, null: false, default: ""
    end
  end
  