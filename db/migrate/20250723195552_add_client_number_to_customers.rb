class AddClientNumberToCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :customers, :client_number, :string, null: false
    add_index  :customers, :client_number, unique: true
  end
end
