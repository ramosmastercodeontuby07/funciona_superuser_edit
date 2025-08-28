class AddUserToOrders < ActiveRecord::Migration[8.0]
  def change
    add_reference :orders, :user, foreign_key: true, index: true
  end
end
