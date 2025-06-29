class UserMailer < ApplicationMailer
  default from: "hiyuhiyu915@gmail.com"

  def reset_password_email(user)
    @user = User.find user.id
    @url  = edit_password_reset_url(@user.reset_password_token)
    mail(to: user.email,
         subject: t("defaults.password_reset"))
  end

  def email_change_verification(user)
    @user = user
    @url = confirm_email_change_users_url(token: user.email_change_token)
    mail(to: user.unconfirmed_email,
         subject: t("defaults.email_change_verification"))
  end
end
