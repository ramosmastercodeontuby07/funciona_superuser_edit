class EcommerceController < ApplicationController
  before_action :require_login
  before_action :redirect_finance_if_needed, only: :index
  before_action :load_cart, only: [:index, :add_to_cart, :remove_from_cart, :stats, :checkout]

  # GET /ecommerce
  def index
    authorize :ecommerce, :index?

    # ===== Catálogo por secciones (usando enum con _prefix :sec) =====
    @bebidas      = Product.active.sec_bebidas.order(:name)
    @suplementos  = Product.active.sec_suplementos.order(:name)
    @products     = @bebidas + @suplementos  # por compatibilidad con la vista

    # ===== KPIs del día =====
    today_scope        = Order.where(created_at: Time.zone.today.all_day)
    @today_sales_count = today_scope.count
    @today_sales_total = today_scope.sum(:total).to_f

    week_scope         = Order.where(created_at: Time.zone.now.beginning_of_week..Time.zone.now)
    @week_sales_count  = week_scope.count

    month_scope        = Order.where(created_at: Time.zone.now.beginning_of_month..Time.zone.now)
    @month_sales_count = month_scope.count

    year_scope         = Order.where(created_at: Time.zone.now.beginning_of_year..Time.zone.now)
    @year_sales_count  = year_scope.count

    # ===== Personas que han entrado hoy =====
    @today_access_count = ActivityLog.where(
      action: 'access',
      created_at: Time.zone.today.all_day
    ).count

    # ===== Búsqueda + Control de acceso (usa :search_number) =====
    if params[:search_number].present?
      num = params[:search_number].to_s.strip

      @customer        = Customer.find_by(client_number: num) || Customer.find_by(search_number: num)
      @allowed         = @customer.present?
      @access_customer = @customer

      if @customer
        @access_allowed = @customer.next_payment_date.present? && @customer.next_payment_date >= Date.current

        begin
          ActivityLog.create!(
            user:    current_user,
            action:  'access',
            details: "Acceso #{@access_allowed ? 'permitido' : 'denegado'} " \
                     "para cliente ##{@customer.client_number} (#{@customer.name}) a las " \
                     "#{Time.current.in_time_zone('America/Merida').strftime('%H:%M:%S')}"
          )
        rescue => e
          Rails.logger.warn("No se pudo registrar ActivityLog de acceso: #{e.message}")
        end

        @today_access_count = ActivityLog.where(
          action: 'access',
          created_at: Time.zone.today.all_day
        ).count
      else
        @access_allowed = false
      end
    end
  end

  # POST /ecommerce/add_to_cart
  def add_to_cart
    authorize :ecommerce, :add_to_cart?

    product = Product.active.find_by(id: params[:product_id])
    unless product
      return render json: { success: false, error: "Producto no disponible" }, status: :not_found
    end

    if product.stock.positive?
      @cart[product.id.to_s] ||= 0
      @cart[product.id.to_s] += 1
      product.decrement!(:stock)
      session[:cart] = @cart
      render json: { success: true, new_stock: product.stock }
    else
      render json: { success: false, error: "Sin stock" }, status: :unprocessable_entity
    end
  end

  # DELETE /ecommerce/remove_from_cart
  def remove_from_cart
    authorize :ecommerce, :remove_from_cart?

    product = Product.find_by(id: params[:product_id])
    return render json: { success: false, error: "Producto no encontrado" }, status: :not_found unless product

    pid = product.id.to_s
    if @cart[pid].to_i.positive?
      @cart[pid] -= 1
      product.increment!(:stock)
      @cart.delete(pid) if @cart[pid] <= 0
      session[:cart] = @cart
      render json: { success: true, new_stock: product.stock }
    else
      render json: { success: false, error: "Producto no en carrito" }, status: :unprocessable_entity
    end
  end

  # POST /ecommerce/checkout
  def checkout
    authorize :ecommerce, :add_to_cart?

    if @cart.blank?
      redirect_to ecommerce_path, alert: "No hay productos en el carrito." and return
    end

    pm = params.dig(:order, :payment_method).to_s.strip.downcase
    pm = "efectivo" if pm.blank?
    unless %w[efectivo transferencia].include?(pm)
      redirect_to ecommerce_path, alert: "Método de pago inválido." and return
    end

    order = current_order

    Order.transaction do
      order.order_items.delete_all if order.order_items.exists?
      build_order_items_from_cart!(order, @cart)
      order.payment_method = pm
      order.recalc_total!
    end

    reset_current_order!
    session.delete(:cart)

    # ✅ Ya NO redirige a stats; nos quedamos en eCommerce
    redirect_to ecommerce_path, notice: "Venta registrada (#{pm})."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to ecommerce_path, alert: "No se pudo cerrar la venta: #{e.message}"
  end

  # GET /ecommerce/stats
  def stats
    authorize :ecommerce, :stats?

    from, to = extract_range(params)

    orders   = Order.includes(:user, order_items: :product).where(created_at: from..to)
    sum_expr = "order_items.quantity * order_items.price"

    @orders        = orders.order(:created_at)
    @orders_count  = orders.count
    @gross_total   = orders.joins(:order_items).sum(sum_expr).to_f
    @avg_ticket    = @orders_count.positive? ? (@gross_total / @orders_count) : 0.0

    by_method = orders.joins(:order_items).group(:payment_method).sum(sum_expr)
    exporter  = StatsExporter.new(from: from, to: to)
    # ✅ Solo efectivo + transferencia
    @cash_total, @transfer_total = exporter.send(:buckets_from, by_method)
    @cashier_total = @cash_total + @transfer_total

    @registered_customers = Customer.where(created_at: from..to).order(:created_at)
    @registered_count     = @registered_customers.size
    @visitors             = ActivityLog.where(action: 'access', created_at: from..to)
    @visitors_count       = @visitors.count
    @clients_total        = @registered_count + @visitors_count

    @by_day_total    = orders.joins(:order_items).group("DATE(orders.created_at)").sum(sum_expr)
    @by_day_orders   = orders.group("DATE(orders.created_at)").count
    @by_day_method   = orders.joins(:order_items).group("DATE(orders.created_at)", :payment_method).sum(sum_expr)
    @visitors_by_day = @visitors.group("DATE(created_at)").count

    @date_label = (I18n.l(from.to_date, format: :long, locale: :es) rescue from.strftime("%d %B %Y"))
    @from, @to  = from, to

    respond_to do |format|
      format.html { render :stats }
      format.csv  do
        send_data StatsExporter.new(from: from, to: to).to_csv,
                  filename: "corte_#{from.to_date}_#{to.to_date}.csv",
                  type: "text/csv; charset=utf-8"
      end
      format.xlsx do
        response.headers['Content-Disposition'] =
          "attachment; filename=corte_#{from.to_date}_#{to.to_date}.xlsx"
        # Renderiza app/views/ecommerce/stats.xlsx.axlsx (si lo tienes)
      end
    end
  end

  private

  def redirect_finance_if_needed
    redirect_to finance_path if current_user&.respond_to?(:finance_admin?) && current_user.finance_admin?
  end

  def load_cart
    session[:cart] ||= {}
    @cart = session[:cart]
  end

  # Convierte el carrito de sesión en order_items persistentes
  def build_order_items_from_cart!(order, cart_hash)
    cart_hash.each do |pid, qty|
      qty_i = qty.to_i
      next if qty_i <= 0

      product = Product.find_by(id: pid)
      next unless product

      item = order.order_items.create!(
        product:  product,
        quantity: qty_i,
        price:    product.price.to_f
      )
      if item.has_attribute?(:cost_at_sale) && product.respond_to?(:cost_price)
        item.update_column(:cost_at_sale, product.cost_price.to_f)
      end
    end
  end

  # Devuelve [from, to]
  def extract_range(params)
    now = Time.zone.now
    from =
      if params[:from].present?
        Time.zone.parse(params[:from]).beginning_of_day
      else
        now.beginning_of_day
      end
    to =
      if params[:to].present?
        Time.zone.parse(params[:to]).end_of_day
      else
        now.end_of_day
      end
    [from, to]
  rescue
    [now.beginning_of_day, now.end_of_day]
  end
end
