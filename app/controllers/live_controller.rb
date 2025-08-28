# app/controllers/live_controller.rb
class LiveController < ApplicationController
    # Devuelve solo el fragmento HTML para insertar con Stimulus
    def sales_today
      # Ventas de HOY según tu zona horaria de la app
      start_time = Time.zone.now.beginning_of_day
      end_time   = Time.zone.now.end_of_day
  
      @order_items = OrderItem.includes(:product)
                              .where(created_at: start_time..end_time)
                              .order(created_at: :desc)
  
      # Si tu tabla usa otros nombres de columnas, ajusta aquí:
      # total = SUM(quantity * price)
      @total = @order_items.sum("quantity * price")
  
      render partial: "live/sales_today"
    end
  end
  