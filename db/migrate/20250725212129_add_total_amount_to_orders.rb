# db/migrate/20250725XXXXXX_add_total_amount_to_orders.rb
class AddTotalAmountToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :total_amount, :decimal, precision: 10, scale: 2, null: false, default: 0
  end
end
