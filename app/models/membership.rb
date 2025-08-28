class Membership < ApplicationRecord
  belongs_to :customer
  belongs_to :order, optional: true
  belongs_to :user,  optional: true

  validates :plan, inclusion: { in: %w[mes semana dia] }
  validates :started_on, :ends_on, presence: true

  scope :recent, -> { order(started_on: :desc, id: :desc) }

  def plan_label
    case plan
    when 'semana' then "Plan Semanal"
    when 'dia'    then "Plan Diario"
    else               "Plan Mensual"
    end
  end
end
