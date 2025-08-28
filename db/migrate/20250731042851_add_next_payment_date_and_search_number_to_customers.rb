class AddNextPaymentDateAndSearchNumberToCustomers < ActiveRecord::Migration[6.1]
  def change
    add_column :customers, :next_payment_date, :date
    add_column :customers, :search_number,     :string
  end
end
