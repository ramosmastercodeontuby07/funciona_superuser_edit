class CreateMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :memberships do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :order,    null: true,  foreign_key: true
      t.references :user,     null: true,  foreign_key: true

      t.string  :plan,           null: false        # "mes" / "semana" / "dia"
      t.date    :started_on,     null: false
      t.date    :ends_on,        null: false
      t.decimal :amount,         precision: 10, scale: 2, null: false, default: 0
      t.string  :payment_method, null: true         # "efectivo" / "transferencia"
      t.boolean :paid,           null: false, default: true
      t.text    :notes

      t.timestamps
    end

    add_index :memberships, [:customer_id, :started_on]
  end
end
