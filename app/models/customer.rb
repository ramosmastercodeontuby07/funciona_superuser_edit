# app/models/customer.rb
class Customer < ApplicationRecord
  PLANS = {
    "mes"    => { label: "Plan Mensual",  days: 30, price: 200 },
    "semana" => { label: "Plan Semanal",  days: 7,  price: 100 },
    "dia"    => { label: "Plan Diario",   days: 1,  price: 30  }
  }.freeze

  has_one_attached :photo

  has_many :payments,    dependent: :destroy
  has_many :memberships, dependent: :destroy

  # Purga la foto de forma asíncrona para no bloquear la eliminación
  after_destroy_commit -> { photo.purge_later rescue nil }

  before_validation :normalize_strings
  before_validation :assign_defaults_on_create, on: :create

  validates :client_number,
            presence: true,
            uniqueness: true,
            numericality: { only_integer: true, greater_than: 0 }

  validates :search_number,
            presence: true,
            uniqueness: true

  validates :name,              presence: true
  validates :enrollment_date,   presence: true
  validates :next_payment_date, presence: true
  validates :plan,              presence: true, inclusion: { in: PLANS.keys, message: "debe ser mes, semana o dia" }

  validate  :next_payment_after_enrollment

  scope :plan_mes,    -> { where(plan: "mes") }
  scope :plan_semana, -> { where(plan: "semana") }
  scope :plan_dia,    -> { where(plan: "dia") }

  def plan_key      = (plan.presence || "mes").to_s
  def plan_label    = PLANS[plan_key][:label]
  def plan_days     = PLANS[plan_key][:days]
  def default_price = PLANS[plan_key][:price]

  def self.next_client_number
    if columns_hash['client_number']&.type == :integer
      return maximum(:client_number).to_i + 1
    end

    adapter = connection.adapter_name.to_s.downcase
    max =
      if adapter.include?('postgres')
        connection.select_value(<<~SQL).to_i
          SELECT COALESCE(MAX((client_number)::integer), 0)
          FROM customers
          WHERE client_number ~ '^[0-9]+$'
        SQL
      else
        connection.select_value(<<~SQL).to_i
          SELECT COALESCE(MAX(CAST(client_number AS INTEGER)), 0)
          FROM customers
        SQL
      end
    max + 1
  end

  private

  def normalize_strings
    self.name          = name.to_s.strip
    normalized_plan    = plan.to_s.strip.downcase
    normalized_plan    = normalized_plan.tr("á", "a") # "día" -> "dia"
    self.plan          = normalized_plan.presence
    self.search_number = search_number.to_s.strip.presence
  end

  def assign_defaults_on_create
    self.client_number   ||= self.class.next_client_number
    self.search_number   ||= client_number.to_s
    self.enrollment_date ||= Date.current
    self.next_payment_date ||= (enrollment_date + plan_days.days) if next_payment_date.blank?
  end

  def next_payment_after_enrollment
    return unless enrollment_date && next_payment_date
    errors.add(:next_payment_date, "no puede ser anterior a la fecha de inscripción") if next_payment_date < enrollment_date
  end
end
