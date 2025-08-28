# app/policies/customer_policy.rb
class CustomerPolicy < ApplicationPolicy
  # Cualquiera logueado puede ver la lista y un registro individual
  def index?;  user.present?; end
  def show?;   index?;        end

  # Normal y superuser pueden registrar (new/create)
  def new?;    user.normal? || user.superuser?; end
  def create?; new?;                             end

  # Solo superuser puede editar/actualizar/eliminar
  def edit?;    user.superuser?; end
  def update?;  edit?;           end
  def destroy?; user.superuser?; end
end
