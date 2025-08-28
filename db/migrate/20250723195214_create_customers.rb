class CreateCustomers < ActiveRecord::Migration[7.0]
  def change
    create_table :customers do |t|
      t.string :name,            null: false
      t.date   :enrollment_date, null: false
      t.string :plan,            null: false  # "semana", "mes" o "anio"

      t.timestamps
    end

    add_index :customers, :name, unique: true
  end
end
