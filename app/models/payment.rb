class Payment < ApplicationRecord
  belongs_to :customer
  has_one_attached :photo

  validates :full_name, :plan_type, :payment_method, :cost, presence: true
  validates :plan_type,      inclusion: { in: %w[dia semana mes] }
  validates :payment_method, inclusion: { in: %w[efectivo transferencia] }
  validates :age, numericality: { only_integer: true, greater_than: 0 }, allow_blank: true
  validates :weight, numericality: { greater_than: 0 }, allow_blank: true
  validates :cost, numericality: { greater_than_or_equal_to: 0 }
end
