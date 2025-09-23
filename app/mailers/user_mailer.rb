class UserMailer < ApplicationMailer
  # Mailgunで認証済みのドメインを使用
  default from: "postmaster@repilog.com"  # または "no-reply@repilog.com"

  def activation_needed_email(user)
    Rails.logger.info "=== Mailgun メール送信開始 ==="
    Rails.logger.info "送信元: postmaster@repilog.com"
    Rails.logger.info "送信先: #{user.email}"
    Rails.logger.info "MAILGUN_SMTP_PASSWORD設定: #{ENV['MAILGUN_SMTP_PASSWORD'].present? ? '設定済み' : '未設定'}"

    @user = user
    @url = activate_user_url(@user.activation_token)

    begin
      result = mail(
        to: user.email,
        subject: t("defaults.activation_needed"),
        from: "postmaster@repilog.com"  # 明示的に指定
      )
      Rails.logger.info "✅ Mailgun メール送信完了"
      result
    rescue Net::SMTPAuthenticationError => e
      Rails.logger.error "❌ Mailgun SMTP認証エラー: #{e.message}"
      Rails.logger.error "ユーザー名: postmaster@repilog.com"
      Rails.logger.error "パスワード設定状況: #{ENV['MAILGUN_SMTP_PASSWORD'].present?}"
      raise e
    rescue => e
      Rails.logger.error "❌ Mailgun送信エラー: #{e.class} - #{e.message}"
      raise e
    end
  end
end
