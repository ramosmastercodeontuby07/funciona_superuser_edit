class EcommercePolicy < Struct.new(:user, :ecommerce)
  # Vista principal de ecommerce
  def index?
    logged_in?
  end

  # Carrito
  def add_to_cart?
    logged_in?
  end

  def remove_from_cart?
    logged_in?
  end

  # (opcional) Checkout explícito
  def checkout?
    logged_in?
  end

  # Reportes / corte: **permitido a usuario normal**
  def stats?
    logged_in?
  end

  # Descargas (CSV/XLSX): **SOLO superusuario**
  def export?
    superuser?
  end

  private

  def logged_in?
    user.present?
  end

  def superuser?
    user.present? && user.respond_to?(:superuser?) && user.superuser?
  end
end
