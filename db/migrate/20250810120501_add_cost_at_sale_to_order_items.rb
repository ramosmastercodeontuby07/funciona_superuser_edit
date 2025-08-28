class AddCostAtSaleToOrderItems < ActiveRecord::Migration[7.1]
  def change
    add_column :order_items, :cost_at_sale, :decimal, precision: 10, scale: 2
  end
end
