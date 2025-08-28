# app/controllers/finance_controller.rb
class FinanceController < ApplicationController
    before_action :require_login
    before_action :ensure_finance_admin!
  
    def index
      tz     = Time.zone
      today  = tz.today.all_day
      week   = tz.now.beginning_of_week..tz.now
      month  = tz.now.beginning_of_month..tz.now
      year   = tz.now.beginning_of_year..tz.now
  
      # KPIs principales
      @customers_total     = Customer.count
      @orders_today_count  = Order.where(created_at: today).count
      @sales_today_total   = Order.where(created_at: today).sum(:total).to_f
  
      # Utilidad
      @profit_today   = profit_for_range(today)
      @profit_week    = profit_for_range(week)
      @profit_month   = profit_for_range(month)
      @profit_year    = profit_for_range(year)
  
      # Ventas por periodo
      @sales_week_total  = Order.where(created_at: week).sum(:total).to_f
      @sales_month_total = Order.where(created_at: month).sum(:total).to_f
      @sales_year_total  = Order.where(created_at: year).sum(:total).to_f
  
      # Top productos por utilidad (últimos 30 días)
      @top_products = top_products_by_profit(30.days.ago..tz.now, limit: 10)
  
      # Resumen mensual por producto (últimos 12 meses)
      @monthly_product_summary = monthly_summary_last_12_months
    end
  
    private
  
    def ensure_finance_admin!
      unless current_user&.finance_admin?
        redirect_to ecommerce_path, alert: "Acceso restringido."
      end
    end
  
    # ====== FIX: calificar columnas ======
    def profit_for_range(range)
      OrderItem.joins(:product)
               .where(order_items: { created_at: range })
               .sum(
                 Arel.sql(
                   "order_items.quantity * (order_items.price - COALESCE(order_items.cost_at_sale, products.cost_price, 0))"
                 )
               ).to_f
    end
  
    # ====== FIX: calificar columnas en qty, revenue y profit ======
    def top_products_by_profit(range, limit: 10)
      OrderItem.joins(:product)
               .where(order_items: { created_at: range })
               .group("products.id", "products.name")
               .select(
                 "products.name AS name,
                  SUM(order_items.quantity) AS qty,
                  SUM(order_items.quantity * order_items.price) AS revenue,
                  SUM(order_items.quantity * (order_items.price - COALESCE(order_items.cost_at_sale, products.cost_price, 0))) AS profit"
               )
               .order("profit DESC")
               .limit(limit)
    end
  
    # Resumen mensual por producto (últimos 12 meses) — se hace en Ruby, sin SQL calculado
    def monthly_summary_last_12_months
      from = Time.zone.now.beginning_of_month - 11.months
      items = OrderItem.includes(:product)
                       .where(created_at: from..Time.zone.now)
  
      summary = Hash.new { |h,k| h[k] = Hash.new { |h2,k2| h2[k2] = { revenue: 0.0, profit: 0.0, qty: 0 } } }
  
      items.find_each do |it|
        month = it.created_at.in_time_zone.beginning_of_month.to_date
        name  = it.product&.name || "Desconocido"
        unit_price = it.price.to_f
        unit_cost  = (it.cost_at_sale || it.product&.cost_price || 0).to_f
  
        rev   = it.quantity * unit_price
        prof  = it.quantity * (unit_price - unit_cost)
  
        summary[month][name][:revenue] += rev
        summary[month][name][:profit]  += prof
        summary[month][name][:qty]     += it.quantity
      end
  
      summary.keys.sort.reverse.first(12).map do |month|
        products = summary[month].sort_by { |_name, data| -data[:profit] }.map do |name, data|
          { name: name, qty: data[:qty], revenue: data[:revenue].round(2), profit: data[:profit].round(2) }
        end
        { month: month, products: products }
      end
    end
  end
  