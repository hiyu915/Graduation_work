class ContactMailer < ApplicationMailer
  default to: "hiyuhiyu915@gmail.com"

  def contact_email(contact_form)
    @category = contact_form.category
    @message = contact_form.message
    @user_email = contact_form.email

    mail(
      from: "hiyuhiyu915@gmail.com",
      reply_to: @user_email,
      subject: "お問い合わせがありました"
    )
  end
end
