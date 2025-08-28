# app/models/order.rb
class Order < ApplicationRecord
  belongs_to :user
  has_many   :order_items, dependent: :destroy
end

# app/models/order_item.rb
class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
end
