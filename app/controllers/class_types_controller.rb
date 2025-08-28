# app/controllers/class_types_controller.rb
class ClassTypesController < ApplicationController
  before_action :require_login

  # GET /class_types
  def index
    # Catálogo fijo
    @classes_catalog = [
      { key: 'cardio_dance', name: 'Cardio Dance', price: 15.0 },
      { key: 'jumping',      name: 'Jumping',      price: 50.0 },
      { key: 'stepgym',      name: 'Stepgym',      price: 25.0 }
    ]

    # Ventas del día (independientes del usuario)
    logs = ActivityLog.where(action: 'class_sale', created_at: Time.zone.today.all_day)

    total_amount = 0.0
    total_items  = 0
    logs.find_each do |log|
      begin
        data = JSON.parse(log.details)
        total_amount += data['total'].to_f
        data.fetch('items', []).each { |it| total_items += it['qty'].to_i }
      rescue JSON::ParserError
        # Ignorar logs antiguos que no sean JSON
      end
    end

    @today_classes_total_amount = total_amount
    @today_classes_total_items  = total_items
  end

  # POST /class_types/checkout
  # Acepta:
  #   - Modo catálogo: { items: [{key:'cardio_dance', qty:2}, ...], note: "..." }
  #   - Modo personalizado: { custom_total: 123.45, note: "..." }
  def checkout
    catalog = {
      'cardio_dance' => { name: 'Cardio Dance', price: 15.0 },
      'jumping'      => { name: 'Jumping',      price: 50.0 },
      'stepgym'      => { name: 'Stepgym',      price: 25.0 }
    }

    note          = params[:note].to_s.strip
    custom_total  = params[:custom_total]
    custom_totalf = custom_total.present? ? custom_total.to_f : 0.0

    if custom_totalf.positive?
      ActivityLog.create!(
        user:    current_user,
        action:  'class_sale',
        details: { items: [], total: custom_totalf, mode: 'custom', note: note }.to_json
      )
      return render json: { success: true, total: custom_totalf.round(2) }
    end

    # Modo catálogo
    items = params[:items].to_a
    normalized = []
    total = 0.0

    items.each do |row|
      key = row[:key].presence || row['key']
      qty = (row[:qty] || row['qty']).to_i
      next unless catalog.key?(key) && qty.positive?

      price = catalog[key][:price].to_f
      normalized << { key: key, name: catalog[key][:name], price: price, qty: qty }
      total += price * qty
    end

    if normalized.empty?
      return render json: { success: false, error: 'No hay clases seleccionadas ni precio personalizado' }, status: :unprocessable_entity
    end

    ActivityLog.create!(
      user:    current_user,
      action:  'class_sale',
      details: { items: normalized, total: total, mode: 'catalog', note: note }.to_json
    )

    render json: { success: true, total: total.round(2) }
  rescue => e
    render json: { success: false, error: e.message }, status: :internal_server_error
  end
end
