Rails.application.config.sorcery.submodules = [
  :reset_password,
  :user_activation,
  :external
]

Rails.application.config.sorcery.configure do |config|
  # === デバッグ情報（開発環境のみ）===
  if Rails.env.development?
    Rails.logger.debug "=== OAuth Credentials Debug ==="
    Rails.logger.debug "Google Client ID: #{Rails.application.credentials.dig(:google, :client_id)&.present? ? 'OK' : 'NG'}"
    Rails.logger.debug "Google Client Secret: #{Rails.application.credentials.dig(:google, :client_secret)&.present? ? 'OK' : 'NG'}"
    Rails.logger.debug "Twitter API Key: #{Rails.application.credentials.dig(:twitter2, :api_key)&.present? ? 'OK' : 'NG'}"
    Rails.logger.debug "Twitter API Secret: #{Rails.application.credentials.dig(:twitter2, :api_secret)&.present? ? 'OK' : 'NG'}"
  end

  # === 外部認証プロバイダ設定 ===
  config.external_providers = %i[google twitter]

  # Google OAuth
  config.google.key          = Rails.application.credentials.dig(:google, :client_id)
  config.google.secret       = Rails.application.credentials.dig(:google, :client_secret)
  config.google.callback_url = Rails.env.production? ?
                              "https://repilog.com/oauth/callback?provider=google" :
                              "http://localhost:3000/oauth/callback?provider=google"
  config.google.user_info_mapping = {
    email: "email"
  }
  config.google.scope = "email profile"

  # Twitter OAuth
  config.twitter.key          = Rails.application.credentials.dig(:twitter2, :api_key)
  config.twitter.secret       = Rails.application.credentials.dig(:twitter2, :api_secret)
  config.twitter.callback_url = Rails.env.production? ?
                                "https://repilog.com/oauth/callback?provider=twitter" :
                                "http://localhost:3000/oauth/callback?provider=twitter"
  config.twitter.user_info_mapping = {
    username: "screen_name"
  }

  # === user_config ブロック ===
  config.user_config do |user|
    user.authentications_class = Authentication

    # === user_activation モジュール設定 ===
    user.activation_state_attribute_name             = :activation_state
    user.activation_token_attribute_name             = :activation_token
    user.activation_token_expires_at_attribute_name  = :activation_token_expires_at
    user.activation_token_expiration_period         = 2.hours
    user.user_activation_mailer                     = UserMailer
    user.activation_needed_email_method_name        = :activation_needed_email
    user.activation_success_email_method_name       = :activation_success_email
    user.prevent_non_active_users_to_login          = false

    # === reset_password モジュール設定 ===
    user.reset_password_mailer                      = UserMailer
    user.reset_password_time_between_emails         = 1.hour
  end

  # ⚠️ 重要：この行は必ずuser_configブロックの後に記述
  config.user_class = "User"
end
