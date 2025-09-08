class OauthsController < ApplicationController
  skip_before_action :require_login, only: %i[oauth callback]
  skip_before_action :verify_authenticity_token, only: [:callback, :oauth]

  # OAuth 認証開始
  def oauth
    provider = map_provider(params[:provider])
    unless Sorcery::Controller::Config.external_providers.include?(provider)
      redirect_to login_path, alert: "#{provider.to_s.titleize}はサポートされていません" and return
    end

    Rails.logger.debug("=== MIDDLEWARE CHECK ===")
    Rails.logger.debug("OmniAuth middleware loaded: #{Rails.application.middleware.include?(OmniAuth::Builder)}")
    Rails.logger.debug("Available middleware: #{Rails.application.middleware.map(&:inspect).grep(/omni/i)}")
    
    Rails.logger.debug("=== PROVIDER CHECK ===")
    Rails.logger.debug("Params provider: #{params[:provider]}")
    Rails.logger.debug("Mapped provider: #{map_provider(params[:provider])}")
    Rails.logger.debug("=== PROVIDER CHECK END ===")

    Rails.logger.debug("=== OAuth DEBUG START ===")
    Rails.logger.debug("Provider: #{provider}")
    Rails.logger.debug("Current environment: #{Rails.env}")
    Rails.logger.debug("Expected callback URL: #{url_for(controller: :oauths, action: :callback, provider: provider, only_path: false)}")
    Rails.logger.debug("Sorcery callback URL: #{Sorcery::Controller::Config.send(provider).callback_url}")
    Rails.logger.debug("=== OAuth DEBUG END ===")
    
    Rails.logger.debug("=== GOOGLE CONFIG CHECK ===")
    Rails.logger.debug("Google Client ID present: #{Rails.application.credentials.google&.[](:client_id)&.present? ? 'YES' : 'NO'}")
    Rails.logger.debug("Google Client Secret present: #{Rails.application.credentials.google&.[](:client_secret)&.present? ? 'YES' : 'NO'}")
    Rails.logger.debug("=== GOOGLE CONFIG CHECK END ===")
    
    Rails.logger.debug("=== SORCERY DETAILED CONFIG ===")
    Rails.logger.debug("Sorcery submodules: #{Rails.application.config.sorcery.submodules}")
    Rails.logger.debug("External providers: #{Sorcery::Controller::Config.external_providers}")
    
    if provider == :google && Sorcery::Controller::Config.respond_to?(:google)
      google_config = Sorcery::Controller::Config.google
      Rails.logger.debug("Google config present: #{google_config.present?}")
      Rails.logger.debug("Google key present: #{google_config&.key&.present?}")
      Rails.logger.debug("Google secret present: #{google_config&.secret&.present?}")
      Rails.logger.debug("Google callback URL: #{google_config&.callback_url}")
    end
    Rails.logger.debug("=== SORCERY DETAILED CONFIG END ===")

    login_at(provider) # Sorcery が Google にリダイレクト
  end

  # OAuth コールバック
  def callback
    provider = map_provider(params[:provider])

    if params[:error]
      Rails.logger.error("🚨 OAuth Error in URL params:")
      Rails.logger.error("  Error: #{params[:error]}")
      Rails.logger.error("  Error description: #{params[:error_description]}")
      Rails.logger.error("  Error URI: #{params[:error_uri]}")
      Rails.logger.error("  State: #{params[:state]}")
    end

    Rails.logger.debug("=== REQUEST ENV CHECK ===")
    Rails.logger.debug("omniauth.auth present: #{request.env.key?('omniauth.auth')}")
    Rails.logger.debug("omniauth.origin present: #{request.env.key?('omniauth.origin')}")
    Rails.logger.debug("omniauth.strategy present: #{request.env.key?('omniauth.strategy')}")
    Rails.logger.debug("omniauth.error present: #{request.env.key?('omniauth.error')}")

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

     if request.env['omniauth.error']
      Rails.logger.error("🚨 OmniAuth Error detected:")
      Rails.logger.error("  Type: #{request.env['omniauth.error.type']}")
      Rails.logger.error("  Strategy: #{request.env['omniauth.error.strategy']}")
      Rails.logger.error("  Message: #{request.env['omniauth.error']}")
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

  def failure
    Rails.logger.error("=== OAUTH FAILURE ===")
    Rails.logger.error("Failure reason: #{params[:message]}")
    Rails.logger.error("Strategy: #{params[:strategy]}")
    Rails.logger.error("All params: #{params.inspect}")
    Rails.logger.error("=== OAUTH FAILURE END ===")
    
    redirect_to login_path, alert: "認証に失敗しました: #{params[:message]}"
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
