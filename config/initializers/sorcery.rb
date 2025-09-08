Rails.application.config.sorcery.submodules = [:reset_password, :user_activation, :external]

Rails.application.config.sorcery.configure do |config|
  # ----------------------
  # User関連の設定
  # ----------------------
  config.user_config do |user|
    # -- user_activation --
    user.activation_state_attribute_name = :activation_state
    user.activation_token_attribute_name = :activation_token
    user.activation_token_expires_at_attribute_name = :activation_token_expires_at
    user.activation_token_expiration_period = 2.hours
    user.user_activation_mailer = UserMailer
    user.activation_needed_email_method_name = :activation_needed_email
    user.activation_success_email_method_name = :activation_success_email
    user.prevent_non_active_users_to_login = false

    # -- reset_password --
    user.reset_password_mailer = UserMailer
    user.reset_password_time_between_emails = 1.hour

    # -- external --
    user.authentications_class = Authentication
  end

  # ----------------------
  # External認証設定
  # ----------------------
  config.external_providers = %i[google]

  config.google.key = Rails.application.credentials.dig(:google, :client_id)
  config.google.secret = Rails.application.credentials.dig(:google, :client_secret)
  config.google.callback_url = Rails.env.production? ?
                              "https://repilog.com/oauth/callback?provider=google" :
                              "http://localhost:3000/oauth/callback?provider=google"
  config.google.user_info_mapping = { email: "email"}

  # ----------------------
  # Userクラスの指定は最後に
  # ----------------------
  config.user_class = "User"
end
