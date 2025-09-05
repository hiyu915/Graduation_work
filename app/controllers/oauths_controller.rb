class OauthsController < ApplicationController
  skip_before_action :require_login, only: %i[oauth callback]

  # OAuth 認証開始
  def oauth
    provider = map_provider(params[:provider])
    unless Sorcery::Controller::Config.external_providers.include?(provider)
      redirect_to login_path, alert: "#{provider.to_s.titleize}はサポートされていません" and return
    end

    Rails.logger.debug("[OAuth DEBUG] Starting OAuth for provider: #{provider}")
    login_at(provider) # Sorcery が Google にリダイレクト
  end

  # OAuth コールバック
  def callback
    provider = map_provider(params[:provider])
    Rails.logger.debug("[OAuth DEBUG] Callback received for provider: #{provider}")
    Rails.logger.debug("[OAuth DEBUG] Params: #{params.to_unsafe_h}")

    if params[:error].present?
      redirect_to login_path, alert: "#{provider.to_s.titleize}での認証が拒否されました" and return
    end

    begin
      # 既存ユーザーのログイン
      user = login_from(provider)

      # 新規作成（メールアドレスが取得できる場合のみ）
      if user.nil? && can_create_from_provider?(provider)
        user = create_from(provider)
      end

      if user
        Rails.logger.debug("[OAuth DEBUG] User processed: #{user.inspect}")
        reset_session
        auto_login(user)
        redirect_to root_path, notice: "#{provider.to_s.titleize}でログインしました"
      else
        # メールアドレス未登録の場合は provider 情報だけセッションに保持
        session[:external_auth_data] = { provider: provider }
        Rails.logger.debug("[OAuth DEBUG] User creation returned nil or missing email")
        redirect_to edit_email_form_users_path, alert: "メールアドレスを登録してください"
      end

    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[OAuth ERROR] #{e.class}: #{e.message}\n#{e.record&.errors&.full_messages}")
      redirect_to login_path, alert: "#{provider.to_s.titleize}でユーザー作成に失敗しました"
    rescue StandardError => e
      Rails.logger.error("[OAuth ERROR] #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
      redirect_to login_path, alert: "#{provider.to_s.titleize}でログインに失敗しました"
    end
  end

  private

  # Sorcery external で新規作成可能か判定（0.16.5 用に修正）
  def can_create_from_provider?(_provider)
    User.new.respond_to?(:email)
  end

  # プロバイダ文字列を Sorcery 用シンボルに変換
  def map_provider(provider_param)
    case provider_param.to_s
    when "google" then :google
    when "twitter", "x", "twitter2" then :twitter
    else
      provider_param.present? ? provider_param.to_sym : :google
    end
  end
end
