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
    provider = params[:provider]&.to_sym
    
    Rails.logger.debug("=== ENHANCED OAUTH DEBUG ===")
    Rails.logger.debug("Provider param: #{params[:provider]}")
    Rails.logger.debug("Mapped provider: #{provider}")
    Rails.logger.debug("Request path: #{request.path}")
    Rails.logger.debug("Request method: #{request.method}")
    Rails.logger.debug("All params: #{params.inspect}")
    
    # ★ 重要：Sorcery内部状態の詳細確認
    Rails.logger.debug("Sorcery external_providers: #{Sorcery::Controller::Config.external_providers}")
    Rails.logger.debug("Google callback_url: #{Sorcery::Controller::Config.google.callback_url}")
    Rails.logger.debug("Google scope: #{Sorcery::Controller::Config.google.scope}")
    
    # ★ 重要：request.envの詳細調査
    omniauth_keys = request.env.keys.select { |k| k.to_s.match?(/omni|oauth|auth/) }
    Rails.logger.debug("Auth-related env keys: #{omniauth_keys}")
    
    omniauth_keys.each do |key|
      value = request.env[key]
      if value.is_a?(Hash)
        Rails.logger.debug("  #{key}: #{value.keys}")
      else
        Rails.logger.debug("  #{key}: #{value.inspect}")
      end
    end
    
    # ★ 重要：failure情報の詳細確認
    if request.env['omniauth.error']
      Rails.logger.error("Omniauth Error: #{request.env['omniauth.error']}")
      Rails.logger.error("Error Type: #{request.env['omniauth.error.type']}")
      Rails.logger.error("Error Strategy: #{request.env['omniauth.error.strategy']}")
    end
    
    Rails.logger.debug("=== END ENHANCED DEBUG ===")
    
    # 既存のコールバック処理
    if (@user = login_from(provider))
      redirect_to root_path, notice: "#{provider.to_s.titleize}でログインしました"
    else
      begin
        auth_hash = request.env['omniauth.auth']
        
        if auth_hash.nil?
          Rails.logger.error("❌ auth_hash is still nil after configuration check!")
          redirect_to login_path, alert: "OAuth認証に失敗しました（設定確認後もレスポンス未受信）"
          return
        end
        
        Rails.logger.debug("✅ Auth Hash received!")
        Rails.logger.debug("Auth Hash structure: #{auth_hash.to_hash}")
        
        @user = create_from(provider)
        
        if @user
          redirect_to root_path, notice: "#{provider.to_s.titleize}でアカウントを作成しました"
        else
          Rails.logger.error("User creation failed")
          redirect_to login_path, alert: "ユーザー作成に失敗しました"
        end
        
      rescue StandardError => e
        Rails.logger.error("[OAuth ERROR] #{e.class}: #{e.message}")
        Rails.logger.error("Backtrace: #{e.backtrace.first(5)}")
        redirect_to login_path, alert: "OAuth認証でエラーが発生しました"
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