class ContactMailer < ApplicationMailer
  default to: "hiyuhiyu915@gmail.com"

  def contact_email(contact_form)
    @category = contact_form.category
    @email = contact_form.email
    @message = contact_form.message

    mail(from: @email, subject: "お問い合わせがありました")
  end
end
