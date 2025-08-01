class TestMailerController < ApplicationController
  def send_test
    user = User.last
    UserMailer.activation_needed_email(user).deliver_now
    render plain: "メール送信しました"
  end
end
