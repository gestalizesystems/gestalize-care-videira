class Auth::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :authenticate_user!

  def google_oauth2
    user = User.from_omniauth(request.env["omniauth.auth"])

    if user&.persisted?
      sign_in_and_redirect user, event: :authentication
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
    else
      session["devise.google_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url,
        alert: "Não foi possível autenticar via Google. Verifique seu e-mail."
    end
  end

  def failure
    redirect_to root_path, alert: "Autenticação cancelada."
  end
end
