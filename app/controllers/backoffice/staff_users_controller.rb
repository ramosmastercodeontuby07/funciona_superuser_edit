# app/controllers/backoffice/staff_users_controller.rb
module Backoffice
  class StaffUsersController < ApplicationController
    before_action :require_login
    before_action :require_superuser!
    before_action :set_user, only: [:edit, :update, :destroy]

    # GET /backoffice/staff_users
    def index
      @users = User.with_attached_photo.order(:name)
    end

    # GET /backoffice/staff_users/new
    def new
      @user = User.new
    end

    # POST /backoffice/staff_users
    def create
      is_super = params.dig(:user, :superuser).to_s == "1"

      @user = User.new(user_params)
      @user.role = is_super ? "superuser" : "normal"

      # Para usuarios normales, garantizar string vacío (NO nil) por NOT NULL
      @user.secret_code = "" unless is_super

      # Secret code requerido si es superusuario
      if is_super && @user.secret_code.blank?
        @user.errors.add(:secret_code, "es requerido para superusuario")
        return render :new, status: :unprocessable_entity
      end

      # Foto (opcional)
      @user.photo.attach(params[:user][:photo]) if params.dig(:user, :photo).present?

      if @user.save
        redirect_to backoffice_staff_users_path, notice: "Usuario creado correctamente."
      else
        flash.now[:alert] = @user.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    # GET /backoffice/staff_users/:id/edit
    def edit
    end

    # PATCH/PUT /backoffice/staff_users/:id
    def update
      is_super = params.dig(:user, :superuser).to_s == "1"

      attrs = user_params.to_h

      # No cambiar password si viene vacío
      if attrs['password'].blank? && attrs['password_confirmation'].blank?
        attrs.delete('password')
        attrs.delete('password_confirmation')
      end

      # Rol desde checkbox
      attrs['role'] = is_super ? "superuser" : "normal"

      # Para no-superuser, NUNCA nil en secret_code (por NOT NULL)
      unless is_super
        attrs['secret_code'] = '' if attrs['secret_code'].blank?
      end

      # Secret code requerido si queda como superuser
      if is_super && (attrs['secret_code'].presence || @user.secret_code).blank?
        @user.errors.add(:secret_code, "es requerido para superusuario")
        return render :edit, status: :unprocessable_entity
      end

      # Foto (opcional)
      @user.photo.attach(params[:user][:photo]) if params.dig(:user, :photo).present?

      if @user.update(attrs)
        redirect_to backoffice_staff_users_path, notice: "Usuario actualizado."
      else
        flash.now[:alert] = @user.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /backoffice/staff_users/:id
    def destroy
      if @user == current_user
        return redirect_to backoffice_staff_users_path, alert: "No puedes eliminar tu propio usuario."
      end

      if @user.orders.exists?
        return redirect_to backoffice_staff_users_path, alert: "No se puede eliminar: tiene historial de ventas."
      end

      @user.destroy!
      redirect_to backoffice_staff_users_path, notice: "Usuario eliminado definitivamente."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user)
            .permit(:name, :password, :password_confirmation, :secret_code, :photo)
    end

    def require_superuser!
      allowed =
        (current_user&.respond_to?(:superuser?) && current_user.superuser?) ||
        (current_user&.respond_to?(:role) && current_user.role.to_s == "superuser")
      return if allowed

      redirect_to ecommerce_path, alert: "No autorizado (solo superusuario)."
    end
  end
end
