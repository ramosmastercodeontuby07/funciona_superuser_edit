class AddCostToPayments < ActiveRecord::Migration[6.1]
  def change
    add_column :payments,
               :cost,
               :decimal,
               precision: 8,
               scale: 2,
               null: false,
               default: 0.0
  end
end
