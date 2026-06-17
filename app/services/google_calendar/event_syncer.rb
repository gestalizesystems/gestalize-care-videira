require "google/apis/calendar_v3"
require "signet/oauth_2/client"

module GoogleCalendar
  # Cria e remove eventos na Google Agenda da owner a partir das reservas.
  # Usa o refresh_token guardado na owner (conectado pelo painel admin).
  class EventSyncer
    SCOPE     = "https://www.googleapis.com/auth/calendar.events".freeze
    TIME_ZONE = "America/Fortaleza".freeze

    def self.create_events(booking_group)
      new.create_events(booking_group)
    end

    def self.remove_event(booking)
      new.remove_event(booking)
    end

    # Cria 1 evento por turno (booking) da reserva confirmada.
    def create_events(group)
      return unless connected?

      group.bookings.includes(availability: :service).find_each do |booking|
        next if booking.google_event_id.present?

        result = service.insert_event(calendar_id, build_event(group, booking))
        booking.update_column(:google_event_id, result.id)
      end
    end

    # Remove o evento de um turno cancelado.
    def remove_event(booking)
      return unless connected?
      return if booking.google_event_id.blank?

      begin
        service.delete_event(calendar_id, booking.google_event_id)
      rescue Google::Apis::ClientError => e
        raise unless e.status_code == 404 # já não existe — ok
      end
      booking.update_column(:google_event_id, nil)
    end

    private

    def calendar_id
      ENV.fetch("GOOGLE_CALENDAR_ID", "primary")
    end

    def connected?
      owner&.google_refresh_token.present?
    end

    def owner
      @owner ||= User.where(role: "owner").where.not(google_refresh_token: nil).first
    end

    def service
      @service ||= Google::Apis::CalendarV3::CalendarService.new.tap do |svc|
        svc.authorization = build_authorizer
      end
    end

    def build_authorizer
      client = Signet::OAuth2::Client.new(
        token_credential_uri: "https://oauth2.googleapis.com/token",
        client_id:            ENV["GOOGLE_CLIENT_ID"],
        client_secret:        ENV["GOOGLE_CLIENT_SECRET"],
        refresh_token:        owner.google_refresh_token,
        scope:                SCOPE
      )
      client.fetch_access_token!
      client
    end

    def build_event(group, booking)
      av    = booking.availability
      sala  = av.service&.name.presence || "Sala"
      zone  = ActiveSupport::TimeZone[TIME_ZONE]
      starts = zone.local(av.date.year, av.date.month, av.date.day, av.starts_at.hour, av.starts_at.min)
      ends   = zone.local(av.date.year, av.date.month, av.date.day, av.ends_at.hour, av.ends_at.min)

      Google::Apis::CalendarV3::Event.new(
        summary:     "Aluguel — #{group.dentist.name} — #{sala}",
        description: "Reserva confirmada na Videira Clinic.\n" \
                     "Dentista: #{group.dentist.name}\nSala: #{sala}",
        start: Google::Apis::CalendarV3::EventDateTime.new(date_time: starts.iso8601, time_zone: TIME_ZONE),
        end:   Google::Apis::CalendarV3::EventDateTime.new(date_time: ends.iso8601,   time_zone: TIME_ZONE)
      )
    end
  end
end
