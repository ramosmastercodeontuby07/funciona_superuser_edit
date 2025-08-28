# app/models/product.rb
class Product < ApplicationRecord
  has_one_attached :image

  # ----- Secciones (sin enum) -----
  PRODUCT_SECTIONS = { bebidas: 0, suplementos: 1 }.freeze
  scope :active,          -> { where(active: true) }
  scope :sec_bebidas,     -> { where(product_section: PRODUCT_SECTIONS[:bebidas]) }
  scope :sec_suplementos, -> { where(product_section: PRODUCT_SECTIONS[:suplementos]) }

  # Validaciones
  validates :product_section, presence: true, inclusion: { in: PRODUCT_SECTIONS.values }
  validates :name,  presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :cost,  presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Soft delete helpers
  def deactivate! = update!(active: false)
  def activate!   = update!(active: true)

  # Helpers presentación
  def product_section_name  = PRODUCT_SECTIONS.key(product_section).to_s
  def product_section_label = product_section_name.titleize
  def profit_per_unit       = (price.to_d - cost.to_d)
  
  after_destroy_commit -> { image.purge_later if image.attached? }
end
