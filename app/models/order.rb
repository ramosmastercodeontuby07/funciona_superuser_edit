# app/models/order.rb
class Order < ApplicationRecord
  belongs_to :user
  has_many   :order_items, dependent: :destroy

  # Enum STRING (Rails 8: usa "prefix", no "_prefix")
  enum :payment_method,
       { efectivo: "efectivo", transferencia: "transferencia" },
       prefix: :pm

  # (opcional) si quieres que el enum valide automáticamente:
  # enum ..., validate: true
  validates :payment_method, inclusion: { in: %w[efectivo transferencia] }

  before_validation :set_default_payment_method, on: :create

  scope :paid_cash,     -> { where(payment_method: "efectivo") }
  scope :paid_transfer, -> { where(payment_method: "transferencia") }

  def payment_method_label
    payment_method == "efectivo" ? "Efectivo" : "Transferencia"
  end

  def recalc_total!
    sum = order_items.sum("quantity * price")
    update!(total: sum)
  end

  private
  def set_default_payment_method
    self.payment_method ||= "efectivo"
  end
end
