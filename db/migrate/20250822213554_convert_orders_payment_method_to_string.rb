# db/migrate/XXXXXXXXXXXX_convert_orders_payment_method_to_string.rb
class ConvertOrdersPaymentMethodToString < ActiveRecord::Migration[7.1]
  def up
    # 1) Nueva columna string
    add_column :orders, :payment_method_new, :string

    # 2) Backfill desde integer → string
    # Ajusta los mappings si tu enum previo era distinto.
    execute <<~SQL
      UPDATE orders
      SET payment_method_new = CASE payment_method
        WHEN 0 THEN 'efectivo'
        WHEN 1 THEN 'transferencia'
        WHEN 2 THEN 'transferencia' -- si antes tenías 'tarjeta', lo mapeamos a transferencia
        ELSE 'efectivo'
      END
    SQL

    # 3) Indices/rename (manejo seguro si ya existen/no existen)
    remove_index :orders, :payment_method if index_exists?(:orders, :payment_method)
    remove_column :orders, :payment_method
    rename_column :orders, :payment_method_new, :payment_method
    add_index :orders, :payment_method
  end

  def down
    # Revertir a integer si hiciera falta
    add_column :orders, :payment_method_old, :integer, default: 0, null: false

    execute <<~SQL
      UPDATE orders
      SET payment_method_old = CASE LOWER(payment_method)
        WHEN 'efectivo'      THEN 0
        WHEN 'transferencia' THEN 1
        ELSE 0
      END
    SQL

    remove_index :orders, :payment_method if index_exists?(:orders, :payment_method)
    remove_column :orders, :payment_method
    rename_column :orders, :payment_method_old, :payment_method
    add_index :orders, :payment_method
  end
end
