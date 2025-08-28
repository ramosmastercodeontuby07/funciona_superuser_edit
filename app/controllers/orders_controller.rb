# app/controllers/orders_controller.rb
class OrdersController < ApplicationController
  before_action :force_json_format  # Fuerza respuestas JSON (incluye errores)
  before_action :require_login

  rescue_from ActionController::ParameterMissing, with: :handle_params_missing

  # POST /orders  (JSON)
  # Body esperado:
  # {
  #   items: [{ id: 123, quantity: 2 }, ...],
  #   payment_method: "efectivo" | "transferencia"
  # }
  def create
    # Autorización consistente con el carrito
    authorize :ecommerce, :add_to_cart? if defined?(authorize)

    payload = params.permit(:payment_method, items: [:id, :quantity])
    items   = normalize_items(payload[:items])
    pm      = sanitize_payment_method(payload[:payment_method])

    if items.empty?
      return render json: { success: false, error: "El carrito está vacío." }, status: :unprocessable_entity
    end

    order = nil
    ActiveRecord::Base.transaction do
      # Importante: si usas enum string-backed en Order:
      # enum payment_method: { efectivo: "efectivo", transferencia: "transferencia" }
      order = Order.create!(user: current_user, payment_method: pm, total: 0)

      items.each do |it|
        product = Product.find_by(id: it[:product_id])
        raise ActiveRecord::RecordNotFound, "Producto no encontrado (ID #{it[:product_id]})." unless product

        qty   = it[:quantity]
        price = product.price # snapshot del precio actual

        # NO tocamos stock aquí; ya se ajustó en add_to_cart/remove_from_cart
        order.order_items.create!(
          product:  product,
          quantity: qty,
          price:    price,
          # si tienes la columna cost_at_sale en order_items, la llenamos de forma tolerante
          cost_at_sale: (product.respond_to?(:cost_price) ? product.cost_price :
                         product.respond_to?(:cost)       ? product.cost      : nil)
        )
      end

      order.recalc_total!
    end

    # Log venta (best-effort)
    begin
      label = order.payment_method.to_s.titleize # "Efectivo" / "Transferencia"
      ActivityLog.create!(
        user:    current_user,
        action:  'sale',
        details: "Venta ##{order.id} por $#{sprintf('%.2f', order.total.to_f)} (#{label}) a las " \
                 "#{Time.current.in_time_zone('America/Merida').strftime('%H:%M:%S')}"
      )
    rescue => e
      Rails.logger.warn("ActivityLog sale failed: #{e.message}")
    end

    render json: { success: true, order_id: order.id, total: order.total.to_f }, status: :created

  rescue ActiveRecord::RecordInvalid => e
    msg = (e.record.respond_to?(:errors) ? e.record.errors.full_messages.to_sentence : e.message)
    Rails.logger.warn("Orders#create validation: #{msg}")
    render json: { success: false, error: msg }, status: :unprocessable_entity

  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn("Orders#create not found: #{e.message}")
    render json: { success: false, error: e.message }, status: :not_found

  rescue => e
    Rails.logger.error("Orders#create failed: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    render json: { success: false, error: "Error del servidor" }, status: :internal_server_error
  end

  private

  # items => array de hashes con claves :product_id, :quantity (>=1)
  def normalize_items(raw)
    arr = Array(raw).map do |h|
      {
        product_id: (h[:id] || h["id"]).to_i,
        quantity:   [[(h[:quantity] || h["quantity"]).to_i, 1].max, 999].min
      }
    end
    arr.select { |i| i[:product_id] > 0 }
  end

  # Solo 2 métodos (string enum). Fallback a "efectivo".
  def sanitize_payment_method(val)
    v = val.to_s.strip.downcase
    return "transferencia" if %w[transferencia transfer transf spei].include?(v)
    "efectivo"
  end

  # Hace que este endpoint trate la request como JSON (importante para errores/redirects)
  def force_json_format
    request.format = :json
  end

  def handle_params_missing(e)
    render json: { success: false, error: e.message }, status: :bad_request
  end
end
