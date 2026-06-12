class BookingPolicy < ApplicationPolicy
  def show?   = owner_or_dentist?
  def cancel? = record.confirmed? && owner_or_dentist?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.owner?
        scope.joins(:booking_group).where(booking_groups: { clinic_id: user.clinic_id })
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
