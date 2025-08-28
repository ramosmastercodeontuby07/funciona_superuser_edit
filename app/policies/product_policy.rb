# app/policies/product_policy.rb
class ProductPolicy < ApplicationPolicy
    def index?;   true;               end
    def show?;    true;               end
    def create?;  user.superuser?;    end
    def update?;  user.superuser?;    end
    def destroy?; user.superuser?;    end
  end
  