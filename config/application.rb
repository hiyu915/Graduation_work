require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Myapp
  class Application < Rails::Application
    config.load_defaults 7.1
    config.autoload_lib(ignore: %w[assets tasks])

    config.generators do |g|
      g.skip_routes true
      g.helper false
      g.test_framework nil
    end

    config.i18n.default_locale = :ja
    config.time_zone = "Tokyo"

    # ★ 修正：OmniAuthミドルウェアの設定を削除
    # config/initializers/omniauth.rbに統一するため、ここからは削除

    # ★ 追加：OmniAuth全体設定のみ
    config.after_initialize do
      OmniAuth.config.allowed_request_methods = [:post, :get]
      OmniAuth.config.silence_get_warning = true
    end
  end
end