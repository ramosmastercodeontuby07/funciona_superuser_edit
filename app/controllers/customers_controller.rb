# app/controllers/customers_controller.rb
require "base64"
require "stringio"
require "bigdecimal"
require "bigdecimal/util"

class CustomersController < ApplicationController
  before_action :require_login
  # Editar/actualizar/eliminar: solo superusuario. Registrar/ver Sí pueden otros roles.
  before_action :ensure_superuser!, only: [:edit, :update, :destroy]
  before_action :set_customer,      only: [:show, :edit, :update, :destroy]

  # GET /customers
  def index
    q      = params[:q].to_s.strip
    filter = params[:filter].presence || 'name'

    scope   = Customer.all
    adapter = ActiveRecord::Base.connection.adapter_name.to_s.downcase

    if q.present?
      case filter
      when 'name'
        scope =
          if adapter.include?('postgres')
            scope.where('name ILIKE ?', "%#{q}%")
          else
            scope.where('LOWER(name) LIKE ?', "%#{q.downcase}%")
          end
      when 'number'
        scope = numeric_equals(scope, :client_number, q)
      when 'month'
        if (rng = month_range_from(q))
          scope = scope.where(enrollment_date: rng)
        end
      end
    end

    @customers = scope.order(Arel.sql(numeric_order_sql(:client_number)))
    authorize @customers if defined?(authorize)
  end

  # GET /customers/:id
  def show
    authorize @customer if defined?(authorize)

    # Contador de accesos de por vida usando client_number en details de ActivityLog
    pattern = "cliente ##{@customer.client_number}"
    @access_count = ActivityLog
                      .where(action: 'access')
                      .where("details LIKE ?", "%#{pattern}%")
                      .count

    @access_logs = ActivityLog
                     .where(action: 'access')
                     .where("details LIKE ?", "%#{pattern}%")
                     .order(created_at: :desc)
                     .limit(50)
  end

  # GET /customers/new
  def new
    @customer = Customer.new(
      client_number:   next_client_number,
      enrollment_date: Date.current
    )
    authorize @customer if defined?(authorize)
  end

  # POST /customers
  # 1) Guarda cliente SIEMPRE (si valida)
  # 2) Intenta crear venta (no bloquea si falla)
  # 3) Redirige a listado con mensaje claro
  def create
    @customer = Customer.new(customer_params)
    authorize @customer if defined?(authorize)

    # Defaults mínimos
    @customer.client_number   ||= next_client_number
    @customer.enrollment_date ||= Date.current
    @customer.search_number   ||= @customer.client_number.to_s

    # Próxima fecha por plan
    if @customer.next_payment_date.blank?
      @customer.next_payment_date =
        case @customer.plan.to_s.downcase
        when 'dia', 'día' then @customer.enrollment_date + 1.day
        when 'semana'     then @customer.enrollment_date + 7.days
        else                    @customer.enrollment_date + 30.days
        end
    end

    # Foto opcional (upload o base64). Si es inválida o no hay, se omite sin romper.
    attach_photo!(@customer)

    if @customer.save
      # Log de alta (best-effort)
      begin
        ActivityLog.create!(
          user:    current_user,
          action:  'enrollment',
          details: "Inscribió cliente ##{@customer.client_number} (#{@customer.name}) a las " \
                   "#{Time.current.in_time_zone('America/Merida').strftime('%H:%M:%S')}"
        )
      rescue => e
        Rails.logger.warn("ActivityLog enrollment failed: #{e.message}")
      end

      # Venta “best-effort”
      sale_msg = perform_enrollment_sale_for(@customer)

      redirect_to customers_path, notice: "Cliente inscrito correctamente. #{sale_msg}"
    else
      flash.now[:alert] = @customer.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  # GET /customers/:id/edit
  def edit
    authorize @customer if defined?(authorize)
  end

  # PATCH/PUT /customers/:id
  def update
    authorize @customer if defined?(authorize)

    attach_photo!(@customer) # opcional
    if @customer.update(customer_params)
      begin
        ActivityLog.create!(
          user:    current_user,
          action:  'update',
          details: "Actualizó cliente ##{@customer.client_number} (#{@customer.name}) a las " \
                   "#{Time.current.in_time_zone('America/Merida').strftime('%H:%M:%S')}"
        )
      rescue => e
        Rails.logger.warn("ActivityLog update failed: #{e.message}")
      end
      redirect_to customers_path, notice: 'Cliente actualizado correctamente.'
    else
      flash.now[:alert] = @customer.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /customers/:id
  def destroy
    authorize @customer if defined?(authorize)
    info = "##{@customer.client_number} (#{@customer.name})"
    @customer.destroy

    begin
      ActivityLog.create!(
        user:    current_user,
        action:  'destroy',
        details: "Eliminó cliente #{info} a las " \
                 "#{Time.current.in_time_zone('America/Merida').strftime('%H:%M:%S')}"
      )
    rescue => e
      Rails.logger.warn("ActivityLog destroy failed: #{e.message}")
    end

    respond_to do |format|
      format.html { redirect_to customers_path, notice: 'Cliente eliminado correctamente.' }
      format.turbo_stream { redirect_to customers_path, notice: 'Cliente eliminado correctamente.' }
      format.json { render json: { success: true } }
    end
  end

  private

  # ===== Venta best-effort al inscribir =====
  def perform_enrollment_sale_for(customer)
    pm = sanitize_payment_method(params.dig(:customer, :payment_method))

    plan_key    = normalize_plan_key(customer.plan)
    plan_label  = plan_label_for(plan_key)
    fixed_price = fixed_price_for(plan_key)

    custom_price_param = params[:custom_price].to_s
    custom_price = custom_price_param.present? ? (BigDecimal(custom_price_param) rescue 0) : 0
    price_to_charge = custom_price.positive? ? custom_price : fixed_price

    product = plan_product_for(plan_key, plan_label)
    unless product
      return "Se omitió la venta (no hay producto '#{plan_label}' ni 'Membresía')."
    end

    begin
      order = Order.create!(user: current_user, payment_method: pm)
      order.order_items.create!(
        product:  product,
        quantity: 1,
        price:    price_to_charge
      )
      order.recalc_total!

      ActivityLog.create!(
        user:    current_user,
        action:  'sale',
        details: "Venta plan #{plan_label} por #{pm} (#{sprintf("$%.2f", order.total.to_f)})"
      ) rescue nil

      "Se cobró #{plan_label} por #{pm}."
    rescue => e
      Rails.logger.warn("Enrollment sale failed: #{e.message}")
      "Se registró el cliente, pero la venta se omitió."
    end
  end

  # ===== Helpers de búsqueda/orden numérico =====
  def numeric_order_sql(column)
    col = column.to_s
    if Customer.columns_hash[col]&.type == :integer
      "#{col} ASC"
    else
      adapter = ActiveRecord::Base.connection.adapter_name.to_s.downcase
      if adapter.include?('postgres')
        "(#{col})::integer ASC"
      else
        "CAST(#{col} AS INTEGER) ASC"
      end
    end
  end

  def numeric_equals(scope, column, value)
    col = column.to_s
    if Customer.columns_hash[col]&.type == :integer
      scope.where(col => value.to_i)
    else
      adapter = ActiveRecord::Base.connection.adapter_name.to_s.downcase
      if adapter.include?('postgres')
        scope.where("(#{col})::integer = ?", value.to_i)
      else
        scope.where("CAST(#{col} AS INTEGER) = ?", value.to_i)
      end
    end
  end

  def month_range_from(q)
    q = q.to_s.strip
    return nil if q.empty?
    parsed = (Date.strptime(q, '%Y-%m') rescue (Date.strptime(q, '%m/%Y') rescue nil))
    return nil unless parsed
    parsed.beginning_of_month..parsed.end_of_month
  end

  # ===== Strong params =====
  def customer_params
    params.require(:customer).permit(
      :name,
      :client_number,
      :enrollment_date,
      :next_payment_date,
      :plan,
      :search_number,
      :photo,   # ActiveStorage
      :phone,
      :email
    )
  end

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def ensure_superuser!
    unless current_user.superuser?
      redirect_to ecommerce_path, alert: 'Acceso denegado: solo superusuarios pueden gestionar clientes.'
    end
  end

  def next_client_number
    if Customer.respond_to?(:next_client_number)
      Customer.next_client_number
    else
      Customer.maximum(:client_number).to_i + 1
    end
  end

  # ===== Foto (upload o base64) — tolerante =====
  def attach_photo!(_customer)
    # 1) Archivo subido
    if (up = params.dig(:customer, :photo_upload)).present?
      @customer.photo.attach(up)
      return
    end
    # 2) Base64 (opcional)
    b64 = params[:photo_data].to_s
    return if b64.blank?
    decoded = safe_decode_data_url(b64)
    return unless decoded
    @customer.photo.attach(
      io: StringIO.new(decoded[:data]),
      filename: "customer_#{Time.now.to_i}.#{decoded[:ext]}",
      content_type: decoded[:mime]
    )
  end

  def safe_decode_data_url(data_url)
    m = data_url.match(/\Adata:(?<mime>[^;]+);base64,(?<b64>.+)\z/)
    return nil unless m
    mime = m[:mime]
    b64  = m[:b64] rescue nil
    return nil if b64.blank?
    data = Base64.decode64(b64) rescue nil
    return nil unless data
    ext  = Rack::Mime::MIME_TYPES.invert[mime] || mime.to_s.split('/').last
    { mime: mime, ext: ext, data: data }
  end

  # ===== Planes / Productos / Pago =====
  def sanitize_payment_method(val)
    v = val.to_s.strip.downcase
    return "transferencia" if %w[transferencia transfer transf spei].include?(v)
    "efectivo"
  end

  def normalize_plan_key(val)
    key = val.to_s.strip.downcase
    key = key.tr("á", "a") # "día" -> "dia"
    %w[mes semana dia].include?(key) ? key : "mes"
  end

  def plan_label_for(plan_key)
    case plan_key
    when 'semana' then "Plan Semanal"
    when 'dia'    then "Plan Diario"
    else               "Plan Mensual"
    end
  end

  def fixed_price_for(plan_key)
    case plan_key
    when 'semana' then 100
    when 'dia'    then 30
    else               200
    end
  end

  def product_scope
    Product.respond_to?(:active) ? Product.active : Product.all
  end

  def plan_product_for(_plan_key, plan_label)
    product_scope.find_by(name: plan_label) ||
      product_scope.find_by(name: "Membresía") ||
      product_scope.find_by(name: "Membresia")
  end
end
