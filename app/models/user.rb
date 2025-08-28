# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  # Archivos
  has_one_attached :photo

  # Asociaciones
  has_many :activity_logs, dependent: :destroy
  has_many :orders,        dependent: :destroy

  # Constantes
  ROLES = %w[normal superuser].freeze
  FINANCE_NAMES = ['mike', 'jorge vargas', 'yamil vargas'].freeze

  # Normaliza antes de validar
  before_validation :normalize_fields

  # Validaciones base
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :secret_code, presence: true, if: :superuser?

  validate :photo_format

  # Helpers de rol
  def superuser? = role == 'superuser'
  def normal?    = role == 'normal'

  # Solo estos 3 usuarios verán el panel de finanzas
  def finance_admin?
    FINANCE_NAMES.include?(normalized_name)
  end

  def normalized_name
    name.to_s.strip.downcase
  end

  private

  def normalize_fields
    self.name = name.to_s.strip
    self.role = role.to_s.strip.downcase.presence || 'normal'

    if superuser?
      # Para superusuario, se valida presencia; permitir nil aquí si viene vacío
      self.secret_code = secret_code.to_s.strip.presence
    else
      # Para usuario normal NUNCA nil (evita violar NOT NULL); usa cadena vacía
      self.secret_code = secret_code.to_s
    end
  end

  def photo_format
    return unless photo.attached?
    unless photo.content_type.in?(%w[image/png image/jpg image/jpeg])
      errors.add(:photo, 'debe ser PNG, JPG o JPEG')
    end
  end
end
