class ContactsController < ApplicationController
  def new
    @contact_form = ContactForm.new
  end

  def confirm
    @contact_form = ContactForm.new(contact_params)
    if @contact_form.valid?
      render :confirm
    else
      render :new, status: :unprocessable_entity
    end
  end

  def create
    @contact_form = ContactForm.new(contact_params)
    if params[:back]
      render :new
    elsif @contact_form.valid?
      ContactMailer.contact_email(@contact_form).deliver_now
      redirect_to new_contact_path, success: "お問い合わせを送信しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact_form).permit(:email, :category, :message)
  end
end
