# app/controllers/backoffice/products_controller.rb
module Backoffice
    class ProductsController < ApplicationController
      before_action :require_login
      before_action :require_superuser
      before_action :set_product, only: [:edit, :update, :destroy]
  
      def index
        @products = Product.with_attached_image.order(:name)
      end
  
      def new
        @product = Product.new
      end
  
      def create
        @product = Product.new(product_params)
        if @product.save
          redirect_to backoffice_products_path, notice: "Producto creado correctamente."
        else
          flash.now[:alert] = "Revisa los errores."
          render :new, status: :unprocessable_entity
        end
      end
  
      def edit; end
  
      def update
        if @product.update(product_params)
          redirect_to backoffice_products_path, notice: "Producto actualizado."
        else
          flash.now[:alert] = "Revisa los errores."
          render :edit, status: :unprocessable_entity
        end
      end
  
      def destroy
        @product.destroy!
        redirect_to backoffice_products_path, notice: "Producto eliminado definitivamente."
      rescue ActiveRecord::InvalidForeignKey
        @product.update!(active: false)
        redirect_to backoffice_products_path,
                    alert: "El producto tiene historial y no puede eliminarse. Se desactivó (oculto) en la tienda."
      end
  
      private
  
      def set_product
        @product = Product.find(params[:id])
      end
  
      def product_params
        # incluye cost y product_section (entero usando Product::PRODUCT_SECTIONS)
        params.require(:product).permit(
          :name, :price, :cost, :stock, :image, :active, :product_section
        )
      end
  
      def require_superuser
        allowed =
          (current_user&.respond_to?(:superuser?) && current_user.superuser?) ||
          (current_user&.respond_to?(:role) && current_user.role.to_s == "superuser")
        return if allowed
  
        redirect_to ecommerce_path, alert: "No autorizado (solo superusuario)."
      end
    end
  end
  