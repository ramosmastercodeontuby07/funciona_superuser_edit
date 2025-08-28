# app/controllers/products_controller.rb

class ProductsController < ApplicationController
  before_action :require_login
  before_action :require_superuser, only: [:edit, :update, :destroy]

  def edit
    @product = Product.find(params[:id])
  end

  def update
    @product = Product.find(params[:id])
    if @product.update(product_params)
      redirect_to ecommerce_path, notice: "Stock de “#{@product.name}” actualizado a #{@product.stock}."
    else
      flash.now[:alert] = @product.errors.full_messages.to_sentence
      render :edit
    end
  end

  def destroy
    @product = Product.find(params[:id])
    @product.destroy
    redirect_to ecommerce_path, notice: "Producto eliminado."
  end

  private

  def require_superuser
    unless current_user.superuser?
      redirect_to ecommerce_path, alert: "No tienes permisos para esa acción."
    end
  end

  def product_params
    params.require(:product).permit(:stock)
  end
end
