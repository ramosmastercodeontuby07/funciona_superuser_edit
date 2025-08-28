# db/migrate/XXXXXXXXXXXX_add_active_to_products.rb
class AddActiveToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :active, :boolean, default: true, null: false
  end
end
  