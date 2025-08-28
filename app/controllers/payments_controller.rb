class PaymentsController < ApplicationController
  before_action :require_login
  before_action :ensure_superuser!

  # GET /payments/new
  def new
    last_number = Customer.order(:client_number).last&.client_number.to_i
    @payment    = Payment.new(client_number: last_number + 1)
  end

  # POST /payments
  def create
    @payment = Payment.new(payment_params)

    # 1) Crear o actualizar al cliente
    customer = Customer.find_or_initialize_by(client_number: @payment.client_number)
    customer.name            = @payment.full_name
    customer.enrollment_date ||= Date.current
    customer.plan            = @payment.plan_type
    customer.save!  # persiste al socio

    # 2) Asociar la venta al cliente
    @payment.customer = customer

    # 3) Calcular el costo según plan y fecha de inscripción
    @payment.cost = case @payment.plan_type
      when 'dia'    then  30
      when 'semana' then 120
      when 'mes'
        customer.enrollment_date == Date.current ? 265 : 250
    end

    # 4) Guardar la venta con su foto
    if @payment.save
      redirect_to payments_path,
                  notice: 'Venta registrada y cliente guardado correctamente.'
    else
      flash.now[:alert] = @payment.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  private

  def payment_params
    params.require(:payment).permit(
      :full_name,
      :client_number,
      :plan_type,
      :payment_method,
      :age,
      :weight,
      :photo
    )
  end

  def ensure_superuser!
    redirect_to ecommerce_path, alert: 'Acceso denegado' unless current_user.superuser?
  end
end
