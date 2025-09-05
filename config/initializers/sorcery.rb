Rails.application.config.sorcery.submodules = [
  :reset_password,
  :user_activation,
  :external
]

Rails.application.config.sorcery.configure do |config|
  # 使用する User モデル
  config.user_class = "User"

  config.user_config do |user|
    # 認証モデルを明示
    user.authentications_class = "Authentication"

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

  # === 外部認証プロバイダ設定 ===
  config.external_providers = %i[google twitter]

  # Google OAuth
  config.google.key          = Rails.application.credentials.dig(:google, :client_id)
  config.google.secret       = Rails.application.credentials.dig(:google, :client_secret)
  config.google.callback_url = Rails.env.production? ?
                              "https://repilog.com/oauth/callback" :
                              "http://localhost:3000/oauth/callback"
  config.google.user_info_mapping = {
    email:    "email",
    name:     "name",
    username: "name"
  }

  # Twitter OAuth
  config.twitter.key          = Rails.application.credentials.dig(:twitter2, :api_key)
  config.twitter.secret       = Rails.application.credentials.dig(:twitter2, :api_secret)
  config.twitter.callback_url = Rails.env.production? ?
                                "https://repilog.com/oauth/callback?provider=twitter" :
                                "http://localhost:3000/oauth/callback?provider=twitter"
  config.twitter.user_info_mapping = {
    username: "screen_name"
  }
end
