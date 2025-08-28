class SessionsController < ApplicationController
  # Estas acciones no requieren sesión
  skip_before_action :require_login, only: [:new, :create, :check_role, :post_logout_stats]

  def new
  end

  def create
    user = User.find_by(name: params[:name])

    if user &&
       user.authenticate(params[:password]) &&
       (user.normal? || (params[:secret_code].present? && user.secret_code == params[:secret_code]))
      session[:user_id] = user.id

      # Log de inicio de sesión (best-effort)
      begin
        ActivityLog.create!(
          user: user,
          action: 'login',
          details: "Inició sesión a las #{Time.current.in_time_zone('America/Merida').strftime('%H:%M:%S')}"
        )
      rescue => e
        Rails.logger.warn("ActivityLog login failed: #{e.message}")
      end

      redirect_to ecommerce_path, notice: "Bienvenido, #{user.name}"
    else
      flash.now[:alert] = "Credenciales inválidas"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    # Guardamos referencia antes de resetear la sesión para el ticket público
    last_user = current_user

    # Log de cierre de sesión (best-effort)
    if last_user
      begin
        ActivityLog.create!(
          user: last_user,
          action: 'logout',
          details: "Cerró sesión a las #{Time.current.in_time_zone('America/Merida').strftime('%H:%M:%S')}"
        )
      rescue => e
        Rails.logger.warn("ActivityLog logout failed: #{e.message}")
      end
    end

    reset_session

    # Pasamos el usuario por query para que el ticket público muestre inicio/cierre
    redirect_to post_logout_stats_path(
      from: Date.current,
      to:   Date.current,
      uid:  last_user&.id,
      uname: last_user&.name
    )
  end

  def summary
    @session_activities = current_user.activity_logs
                                      .where(action: %w[login logout sale enrollment])
                                      .order(:created_at)
    render :summary
  end

  def check_role
    user = User.find_by(name: params[:name])
    role = if user && user.authenticate(params[:password]) then user.role else 'not_found' end
    render json: { role: role }
  end

  # Página pública para mostrar el "ticket" de stats tras logout
  # También permite consultar cualquier día SIN iniciar sesión.
  def post_logout_stats
    from = params[:from].present? ? Time.zone.parse(params[:from]).beginning_of_day : Time.zone.now.beginning_of_day
    to   = params[:to].present?   ? Time.zone.parse(params[:to]).end_of_day         : Time.zone.now.end_of_day

    orders = Order.includes(:user, order_items: :product).where(created_at: from..to)

    @orders_count = orders.count
    @gross_total  = orders.joins(:order_items).sum("order_items.quantity * order_items.price").to_f
    @avg_ticket   = @orders_count.positive? ? (@gross_total / @orders_count) : 0.0

    # Solo 2 métodos: efectivo y transferencia
    by_method = orders.joins(:order_items).group(:payment_method)
                      .sum("order_items.quantity * order_items.price")

    cash = transfer = 0.0
    by_method.each do |k, v|
      key = k.to_s.downcase.strip
      cash     += v.to_f if %w[efectivo cash].include?(key)
      transfer += v.to_f if %w[transferencia transfer transf spei].include?(key)
    end

    @cash_total     = cash
    @transfer_total = transfer
    @cashier_total  = cash + transfer

    @registered_count = defined?(Customer) ? Customer.where(created_at: from..to).count : 0
    @visitors_count   = ActivityLog.where(action: 'access', created_at: from..to).count
    @clients_total    = @registered_count + @visitors_count

    # Datos de sesión del usuario que cerró sesión (si vienen en params)
    @stats_user_name = params[:uname].presence
    if params[:uid].present?
      if (u = User.find_by(id: params[:uid]))
        @session_login_at  = ActivityLog.where(user: u, action: 'login',  created_at: from..to).minimum(:created_at)
        @session_logout_at = ActivityLog.where(user: u, action: 'logout', created_at: from..to).maximum(:created_at)
        @stats_user_name ||= u.name
      end
    end

    @date_label = (I18n.l(from.to_date, format: :long, locale: :es) rescue from.strftime("%d %B %Y"))

    render "ecommerce/stats"
  end
end
