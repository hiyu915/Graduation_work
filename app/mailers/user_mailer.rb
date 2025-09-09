class UserMailer < ApplicationMailer
  default from: "no-reply@repilog.com"

  def activation_needed_email(user)
    @user = user
    @url  = activate_url(id: @user.activation_token)
    mail(to: user.email, subject: t("defaults.activation_needed"))
  end

  def activation_success_email(user)
    @user = user
    mail(to: user.email, subject: t("defaults.activation_success"))
  end

  def reset_password_email(user)
    @user = user  # ← ここを修正
    @url = edit_password_reset_url(@user.reset_password_token)
    mail(to: user.email, subject: t("defaults.password_reset"))
  end

  def email_change_verification(user)
    @user = user
    @url = confirm_email_change_users_url(token: user.email_change_token)
    mail(to: user.unconfirmed_email,
         subject: t("defaults.email_change_verification"))
  end
end
