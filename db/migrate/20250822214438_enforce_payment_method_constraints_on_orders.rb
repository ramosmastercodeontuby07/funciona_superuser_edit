# db/migrate/XXXXXXXXXXXX_enforce_payment_method_constraints_on_orders.rb
class EnforcePaymentMethodConstraintsOnOrders < ActiveRecord::Migration[7.1]
  def up
    # Normaliza nulos/vacíos antes de poner NOT NULL
    execute "UPDATE orders SET payment_method='efectivo' WHERE payment_method IS NULL OR payment_method=''"
    change_column_default :orders, :payment_method, from: nil, to: "efectivo"
    change_column_null    :orders, :payment_method, false

    # Limita valores permitidos (PostgreSQL y SQLite lo soportan)
    adapter = ActiveRecord::Base.connection.adapter_name.downcase
    if adapter.include?("postgresql") || adapter.include?("sqlite")
      add_check_constraint :orders,
        "payment_method IN ('efectivo','transferencia')",
        name: "orders_payment_method_check"
    end
  end

  def down
    adapter = ActiveRecord::Base.connection.adapter_name.downcase
    if adapter.include?("postgresql") || adapter.include?("sqlite")
      remove_check_constraint :orders, name: "orders_payment_method_check"
    end
    change_column_null    :orders, :payment_method, true
    change_column_default :orders, :payment_method, from: "efectivo", to: nil
  end
end
