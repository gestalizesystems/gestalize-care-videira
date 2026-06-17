require "signet/oauth_2/client"

class Admin::GoogleCalendarController < Admin::BaseController
  SCOPE = "https://www.googleapis.com/auth/calendar.events".freeze

  # Redireciona a owner para o consentimento do Google (acesso offline).
  def connect
    session[:gcal_state] = SecureRandom.hex(16)
    redirect_to oauth_client.authorization_uri(state: session[:gcal_state]).to_s,
      allow_other_host: true
  end

  # Retorno do Google: troca o code pelo refresh_token e guarda na owner.
  def callback
    if params[:state].blank? || params[:state] != session.delete(:gcal_state)
      return redirect_to admin_root_path, alert: "Sessão inválida. Tente conectar novamente."
    end
    if params[:error].present? || params[:code].blank?
      return redirect_to admin_root_path, alert: "Conexão com a Google Agenda cancelada."
    end

    client = oauth_client
    client.code = params[:code]
    client.fetch_access_token!

    if client.refresh_token.present?
      current_user.update!(google_refresh_token: client.refresh_token)
      redirect_to admin_root_path, notice: "Google Agenda conectada com sucesso."
    else
      redirect_to admin_root_path,
        alert: "O Google não enviou o token de atualização. Revogue o acesso antigo em " \
               "myaccount.google.com/permissions e tente conectar de novo."
    end
  rescue => e
    Rails.logger.error("[GoogleCalendar callback] #{e.class}: #{e.message}")
    redirect_to admin_root_path, alert: "Erro ao conectar a Google Agenda."
  end

  def disconnect
    current_user.update!(google_refresh_token: nil)
    redirect_to admin_root_path, notice: "Google Agenda desconectada."
  end

  private

  def oauth_client
    Signet::OAuth2::Client.new(
      authorization_uri:    "https://accounts.google.com/o/oauth2/auth",
      token_credential_uri: "https://oauth2.googleapis.com/token",
      client_id:            ENV["GOOGLE_CLIENT_ID"],
      client_secret:        ENV["GOOGLE_CLIENT_SECRET"],
      scope:                SCOPE,
      redirect_uri:         admin_callback_google_calendar_url,
      additional_parameters: { "access_type" => "offline", "prompt" => "consent" }
    )
  end
end
