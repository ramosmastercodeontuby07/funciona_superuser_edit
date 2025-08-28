class AddPaymentMethodToPayments < ActiveRecord::Migration[6.1]
  def change
    # Sólo añade la columna si NO existe aún
    unless column_exists?(:payments, :payment_method)
      add_column :payments, :payment_method, :string, null: false, default: 'efectivo'
    end
  end
end
