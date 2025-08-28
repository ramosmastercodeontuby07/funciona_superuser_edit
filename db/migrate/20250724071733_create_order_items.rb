# db/migrate/20250725_create_orders_and_order_items.rb
class CreateOrdersAndOrderItems < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.references :user, foreign_key: true, null: false
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.timestamps
    end

    create_table :order_items do |t|
      t.references :order,   foreign_key: true, null: false
      t.references :product, foreign_key: true, null: false
      t.integer    :quantity, null: false
      t.decimal    :unit_price, precision: 10, scale: 2, null: false
      t.timestamps
    end
  end
end
