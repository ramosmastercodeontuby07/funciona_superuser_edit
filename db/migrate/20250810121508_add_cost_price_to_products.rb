class AddCostPriceToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :cost_price, :decimal, precision: 10, scale: 2, default: 0, null: false
  end
end
