class ApplicationController < ActionController::Base
  include ActionController::MimeResponds
  include Pundit::Authorization

  protect_from_forgery with: :exception

  # Evita cachear páginas protegidas (impide verlas con Back tras logout)
  before_action :set_no_cache

  # Zona horaria
  before_action :set_time_zone

  # Autenticación requerida por defecto
  before_action :require_login

  # Manejo de errores comunes
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActionController::InvalidAuthenticityToken, with: :handle_csrf_error

  # Helpers disponibles en vistas/controladores
  helper_method :current_user, :current_order, :reset_current_order!

  private

  # ========== Autenticación ==========
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def require_login
    return if current_user.present?

    respond_to do |format|
      format.json { render json: { success: false, error: "Debes iniciar sesión" }, status: :unauthorized }
      format.any  { redirect_to login_path, alert: "Debes iniciar sesión." }
    end
  end

  def user_not_authorized
    respond_to do |format|
      format.json { render json: { success: false, error: "No autorizado" }, status: :forbidden }
      format.any  { redirect_to login_path, alert: "No autorizado." }
    end
  end

  def handle_csrf_error(_e)
    respond_to do |format|
      format.json { render json: { success: false, error: "CSRF inválido o sesión expirada" }, status: :unprocessable_entity }
      format.any  { redirect_to login_path, alert: "Tu sesión expiró, vuelve a entrar." }
    end
  end

  # ========== Checkout eCommerce: orden de la sesión ==========
  def current_order
    return @current_order if defined?(@current_order)

    @current_order =
      begin
        if session[:order_id]
          o = Order.find_by(id: session[:order_id])
          if o.nil? || (current_user && o.user_id != current_user.id)
            reset_current_order!
            nil
          else
            o
          end
        end
      end

    @current_order ||= start_order!
  end

  def start_order!
    raise Pundit::NotAuthorizedError, "Debes iniciar sesión" unless current_user
    o = Order.create!(user: current_user, payment_method: "efectivo")
    session[:order_id] = o.id
    o
  end

  def reset_current_order!
    session.delete(:order_id)
    @current_order = nil
  end

  # ========== Utilidades ==========
  def set_time_zone
    Time.zone = "America/Merida"
  end

  def set_no_cache
    response.headers["Cache-Control"] = "no-store, no-cache, max-age=0, must-revalidate"
    response.headers["Pragma"]        = "no-cache"
    response.headers["Expires"]       = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
