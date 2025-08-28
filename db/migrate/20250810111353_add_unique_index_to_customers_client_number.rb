# db/migrate/XXXXXXXXXXXX_add_unique_index_to_customers_client_number.rb
class AddUniqueIndexToCustomersClientNumber < ActiveRecord::Migration[7.1]
  def change
    add_index :customers, :client_number, unique: true unless index_exists?(:customers, :client_number, unique: true)
  end
end
