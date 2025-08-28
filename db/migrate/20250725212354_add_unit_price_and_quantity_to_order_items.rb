# db/migrate/20250725XXXXXX_add_unit_price_and_quantity_to_order_items.rb
class AddUnitPriceAndQuantityToOrderItems < ActiveRecord::Migration[7.0]
  def change
    # Agrega unit_price si no existe
    add_column :order_items, :unit_price, :decimal, precision: 10, scale: 2, null: false, default: 0 unless column_exists?(:order_items, :unit_price)
    # Asegúrate de que quantity exista y sea integer
    unless column_exists?(:order_items, :quantity)
      add_column :order_items, :quantity, :integer, null: false, default: 1
    end
  end
end
