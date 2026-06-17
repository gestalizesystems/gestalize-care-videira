class GoogleCalendarSyncJob < ApplicationJob
  queue_as :default

  retry_on Google::Apis::ServerError,        wait: :polynomially_longer, attempts: 3
  retry_on Google::Apis::RateLimitError,     wait: :polynomially_longer, attempts: 3
  retry_on Signet::AuthorizationError,       attempts: 2

  # action: "create" (booking_group_id) | "remove" (booking_id)
  def perform(action, id)
    case action.to_s
    when "create"
      group = BookingGroup.find_by(id: id)
      GoogleCalendar::EventSyncer.create_events(group) if group
    when "remove"
      booking = Booking.find_by(id: id)
      GoogleCalendar::EventSyncer.remove_event(booking) if booking
    end
  end
end
