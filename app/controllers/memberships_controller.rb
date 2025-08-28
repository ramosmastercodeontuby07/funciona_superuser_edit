class MembershipsController < ApplicationController
  before_action :require_login
  before_action :set_customer

  def index
    @memberships = @customer.memberships.recent
  end

  private

  def set_customer
    @customer = Customer.find(params[:customer_id])
  end
end
