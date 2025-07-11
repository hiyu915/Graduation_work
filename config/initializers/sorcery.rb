Rails.application.config.sorcery.submodules = [ :reset_password, :user_activation ]

Rails.application.config.sorcery.configure do |config|
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
  end

  # ✅ config.user_class は一番最後に！
  config.user_class = "User"
end
