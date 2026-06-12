class Current < ActiveSupport::CurrentAttributes
  attribute :clinic

  def self.clinic
    super || (self.clinic = resolve_clinic)
  end

  def self.resolve_clinic
    if ENV["CLINIC_ID"].present?
      Clinic.find_by(id: ENV["CLINIC_ID"])
    end || Clinic.first
  end
end
