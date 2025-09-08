class OauthsController < ApplicationController
  skip_before_action :require_login, only: %i[oauth callback]

  # OAuth 認証開始
  def oauth
    provider = map_provider(params[:provider])
    unless Sorcery::Controller::Config.external_providers.include?(provider)
      redirect_to login_path, alert: "#{provider.to_s.titleize}はサポートされていません" and return
    end

    Rails.logger.debug("=== OAuth DEBUG START ===")
    Rails.logger.debug("Provider: #{provider}")
    Rails.logger.debug("Current environment: #{Rails.env}")
    Rails.logger.debug("Expected callback URL: #{url_for(controller: :oauths, action: :callback, provider: provider, only_path: false)}")
    Rails.logger.debug("Sorcery callback URL: #{Sorcery::Controller::Config.send(provider).callback_url}")
    Rails.logger.debug("=== OAuth DEBUG END ===")

    login_at(provider) # Sorcery が Google にリダイレクト
  end

  # OAuth コールバック
  def callback
    provider = map_provider(params[:provider])

    Rails.logger.debug("=== CALLBACK DEBUG START ===")
    Rails.logger.debug("Provider: #{provider}")
    Rails.logger.debug("Request URL: #{request.url}")
    Rails.logger.debug("Params: #{params.inspect}")
    Rails.logger.debug("Query String: #{request.query_string}")
    Rails.logger.debug("Request env keys: #{request.env.keys.grep(/omni|auth/)}")
    Rails.logger.debug("Auth hash present: #{request.env['omniauth.auth'].present?}")

    if request.env["omniauth.auth"]
      Rails.logger.debug("✅ Auth hash found!")
      Rails.logger.debug("Auth hash: #{request.env['omniauth.auth'].inspect}")
    else
      Rails.logger.debug("❌ No auth hash found in request.env")
      Rails.logger.debug("Available env keys with 'auth': #{request.env.keys.select { |k| k.to_s.include?('auth') }}")
    end

    Rails.logger.debug("=== CALLBACK DEBUG END ===")

    if (@user = login_from(provider))
      redirect_to root_path, notice: "#{provider.to_s.titleize}でログインしました"
    else
      begin
        @user = create_from(provider)
        reset_session
        auto_login(@user)
        redirect_to root_path, notice: "#{provider.to_s.titleize}でログインしました"
      rescue StandardError => e
        Rails.logger.error("OAuth creation error: #{e.message}")
        Rails.logger.error("Backtrace: #{e.backtrace}")
        redirect_to login_path, alert: "#{provider.to_s.titleize}でのログインに失敗しました"
      end
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
