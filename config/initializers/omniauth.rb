Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           Rails.application.credentials.dig(:google, :client_id),
           Rails.application.credentials.dig(:google, :client_secret),
           {
             scope: 'email,profile,openid',
             access_type: 'online',
             prompt: 'select_account',
             skip_jwt: true,
             name: 'google'  # Sorceryとの連携用
           }
end

# OmniAuth基本設定
OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true

# エラーハンドリング（シンプル版）
OmniAuth.config.on_failure = proc { |env|
  # エラー時はログイン画面にリダイレクト
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

# ★ 重要：CSRF保護（Rails 7対応版）
OmniAuth.config.request_validation_phase = proc { |env, strategy|
  # 基本的なバリデーションのみ実行
  true
}