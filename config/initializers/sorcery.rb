Rails.application.config.sorcery.submodules = [
  :reset_password,
  :user_activation,
  :external  # ← 外部認証モジュール
]

Rails.application.config.sorcery.configure do |config|
  # === デバッグ情報（開発環境のみ）===
  if Rails.env.development?
    Rails.logger.debug "=== OAuth Credentials Debug ==="
    Rails.logger.debug "Google Client ID: #{Rails.application.credentials.dig(:google, :client_id)&.present? ? 'OK' : 'NG'}"
    Rails.logger.debug "Google Client Secret: #{Rails.application.credentials.dig(:google, :client_secret)&.present? ? 'OK' : 'NG'}"
  end

  # === 外部認証プロバイダ設定 ===
  config.external_providers = [:google]  # ← まずはGoogleのみでテスト

  # ★ 重要：Google OAuth設定
  config.google.key = Rails.application.credentials.dig(:google, :client_id)
  config.google.secret = Rails.application.credentials.dig(:google, :client_secret)
  config.google.callback_url = Rails.env.production? ?
                              "https://repilog.com/oauth/callback?provider=google" :
                              "http://localhost:3000/oauth/callback?provider=google"
  
  # ★ 重要：user_info_mapping
  config.google.user_info_mapping = {
    email: "email"
  }
  
  # ★ 重要：Google API設定
  config.google.scope = "email profile openid"
  config.google.user_info_url = "https://www.googleapis.com/oauth2/v2/userinfo"

  # === user_config ブロック ===
  config.user_config do |user|
    # ★ 重要：外部認証設定
    user.authentications_class = Authentication
    user.authentications_user_id_attribute_name = :user_id
    user.provider_attribute_name = :provider
    user.provider_uid_attribute_name = :uid

    # === user_activation モジュール設定 ===
    user.activation_state_attribute_name = :activation_state
    user.activation_token_attribute_name = :activation_token
    user.activation_token_expires_at_attribute_name = :activation_token_expires_at
    user.activation_token_expiration_period = 2.hours
    user.user_activation_mailer = UserMailer
    user.activation_needed_email_method_name = :activation_needed_email
    user.activation_success_email_method_name = :activation_success_email
    user.prevent_non_active_users_to_login = false

    # === reset_password モジュール設定 ===
    user.reset_password_mailer = UserMailer
    user.reset_password_time_between_emails = 1.hour

    # === テスト環境設定 ===
    user.stretches = 1 if Rails.env.test?
  end

  # ⚠️ 重要：この行は必ずuser_configブロックの後に記述
  config.user_class = "User"
end