class UserPolicy < ApplicationPolicy
  def index?   = user.owner?
  def show?    = user.owner? || record.id == user.id
  def update?  = user.owner? || record.id == user.id
  def destroy? = user.owner? && record.id != user.id

  class Scope < ApplicationPolicy::Scope
    def resolve
      user.owner? ? scope.where(clinic_id: user.clinic_id) : scope.where(id: user.id)
    end
  end
end
