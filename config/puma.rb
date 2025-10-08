max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Renderで必須の設定
port ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "development" }

# Renderでは0.0.0.0にバインドする必要がある
bind "tcp://0.0.0.0:#{ENV.fetch('PORT') { 3000 }}"

# ワーカー設定（Renderの無料プランでは1推奨）
workers ENV.fetch("WEB_CONCURRENCY") { 1 }

# アプリケーションのプリロード
preload_app!

# PIDファイルの設定
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# プラグイン
plugin :tmp_restart
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# ワーカー起動時の処理
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end
