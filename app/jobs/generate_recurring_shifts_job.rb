class GenerateRecurringShiftsJob < ApplicationJob
  queue_as :low

  def perform
    Clinic.find_each do |clinic|
      RecurringShifts::Generator.advance(clinic)
    rescue => e
      Rails.logger.error("[GenerateRecurringShiftsJob] clinic=#{clinic.id} #{e.class}: #{e.message}")
    end
  end
end
