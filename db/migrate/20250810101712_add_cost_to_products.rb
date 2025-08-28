# db/migrate/XXXXXXXXXXXX_add_cost_to_products.rb
class AddCostToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :cost, :decimal, precision: 10, scale: 2, default: 0, null: false
    add_index  :products, :cost
  end
end
