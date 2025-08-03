class TestMailerController < ApplicationController
  skip_before_action :require_login

  def send_test
    # ダミーユーザーを作成（DBには保存しない）
    user = User.new(
      id: 9999,
      email: "test@example.com",
      activation_token: "dummy_token",
      crypted_password: "dummy"
    )

    # Sorceryが期待するメソッドを最低限モックする
    def user.valid_password?(_); true; end

    UserMailer.activation_needed_email(user).deliver_now
    render plain: "メール送信しました"
  end
end
