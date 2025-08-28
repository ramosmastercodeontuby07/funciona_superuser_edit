class AddFieldsToPayments < ActiveRecord::Migration[6.1]
  def change
    add_column :payments, :full_name,      :string,  null: false, default: ""
    add_column :payments, :client_number,  :integer, null: false
    add_column :payments, :plan_type,      :string,  null: false
    add_column :payments, :age,            :integer
    add_column :payments, :weight,         :float

    add_index  :payments, :client_number, unique: true
  end
end
