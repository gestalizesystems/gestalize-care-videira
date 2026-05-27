class BookingGroupPolicy < ApplicationPolicy
  def show?   = owner_or_dentist?
  def create? = user.dentist?
  def cancel? = owner_or_dentist? && record.pending?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.owner?
        scope.where(clinic_id: user.clinic_id)
      else
        scope.where(dentist_id: user.id)
      end
    end
  end

  private

  def owner_or_dentist?
    user.owner? || record.dentist_id == user.id
  end
end
