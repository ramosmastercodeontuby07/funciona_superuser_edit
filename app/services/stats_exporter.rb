require "csv"

class StatsExporter
  def initialize(from:, to:)
    @from = from
    @to   = to
  end

  def to_csv
    orders   = Order.includes(:user, order_items: :product).where(created_at: @from..@to)
    sum_expr = "order_items.quantity * order_items.price"

    orders_count = orders.count
    gross_total  = orders.joins(:order_items).sum(sum_expr).to_f
    avg_ticket   = orders_count.positive? ? (gross_total / orders_count) : 0.0

    totals_by_method = orders.joins(:order_items).group(:payment_method).sum(sum_expr)
    counts_by_method = orders.group(:payment_method).count
    cash_total, transfer_total = buckets_from(totals_by_method)
    cash_count, transfer_count = buckets_from_counts(counts_by_method)
    cashier_total = cash_total + transfer_total

    registered = defined?(Customer) ? Customer.where(created_at: @from..@to) : Customer.none
    visitors   = ActivityLog.where(action: 'access', created_at: @from..@to)
    visitors_by_day = visitors.group("DATE(created_at)").count

    items_scope      = OrderItem.joins(:order).where(orders: { created_at: @from..@to })
    items_by_product = items_scope.joins(:product).group("products.name").sum("order_items.quantity")

    by_day_total  = orders.joins(:order_items).group("DATE(orders.created_at)").sum(sum_expr)
    by_day_orders = orders.group("DATE(orders.created_at)").count
    by_day_method = orders.joins(:order_items).group("DATE(orders.created_at)", :payment_method).sum(sum_expr)

    CSV.generate(headers: false) do |csv|
      csv << ["Resumen (#{@from.to_date} a #{@to.to_date})"]
      csv << ["Órdenes", orders_count]
      csv << ["Total",   money(gross_total)]
      csv << ["Promedio",money(avg_ticket)]
      csv << ["Efectivo",money(cash_total), cash_count]
      csv << ["Transferencias",money(transfer_total), transfer_count]
      csv << ["Total contado",money(cashier_total)]
      csv << ["Clientes nuevos", registered.count]
      csv << ["Entradas (visitantes)", visitors.count]
      csv << []

      csv << ["Productos vendidos"]
      csv << ["Producto","Cantidad"]
      items_by_product.sort_by { |name, qty| [-qty, name.to_s] }.each { |name, qty| csv << [name, qty] }
      csv << []

      csv << ["Ventas por día"]
      csv << ["Fecha", "Órdenes", "Total", "Efectivo", "Transferencias"]
      days = (by_day_total.keys + by_day_orders.keys + by_day_method.keys.map(&:first)).uniq.compact.sort
      days.each do |day|
        cash_d, transfer_d = buckets_from(
          by_day_method.select { |(d, _), _| d == day }.transform_keys { |(_, m)| m }
        )
        csv << [day, by_day_orders[day].to_i, money(by_day_total[day].to_f), money(cash_d), money(transfer_d)]
      end
      csv << []

      csv << ["Órdenes (detalle)"]
      csv << ["ID", "Fecha/Hora", "Vendedor", "Método", "Total", "Items", "Detalle"]
      orders.find_each do |o|
        total  = o.order_items.sum("quantity * price").to_f
        items  = o.order_items.sum(:quantity)
        detail = o.order_items.map { |it| "#{it.product&.name} x#{it.quantity} @ #{money(it.price)}" }.join(" | ")
        csv << [o.id, o.created_at.in_time_zone("America/Merida").strftime("%Y-%m-%d %H:%M"),
                o.user&.name, o.payment_method, money(total), items, detail]
      end
      csv << []

      csv << ["Accesos por día"]
      csv << ["Fecha", "Entradas"]
      visitors_by_day.sort_by { |k, _| k }.each { |day, cnt| csv << [day, cnt] }
    end
  end

  def to_xlsx = to_csv

  private

  def buckets_from(hash)
    cash = transfer = 0.0
    hash.each do |k, v|
      key = k.to_s.downcase.strip
      cash     += v.to_f if %w[efectivo cash].include?(key)
      transfer += v.to_f if %w[transferencia transfer transf spei].include?(key)
    end
    [cash, transfer]
  end

  def buckets_from_counts(hash)
    cash = transfer = 0
    hash.each do |k, v|
      key = k.to_s.downcase.strip
      cash     += v.to_i if %w[efectivo cash].include?(key)
      transfer += v.to_i if %w[transferencia transfer transf spei].include?(key)
    end
    [cash, transfer]
  end

  def money(n) = sprintf("$%.2f", n.to_f)
end
