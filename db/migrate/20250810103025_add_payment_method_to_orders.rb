# db/migrate/20250819000000_add_payment_method_to_orders.rb
class AddPaymentMethodToOrders < ActiveRecord::Migration[7.1]
  def up
    add_column :orders, :payment_method, :string, default: "efectivo", null: false
    add_index  :orders, :payment_method
  end

  def down
    remove_index  :orders, :payment_method
    remove_column :orders, :payment_method
  end
end
