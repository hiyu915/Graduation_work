# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# supportディレクトリのファイルを読み込み
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]
  config.use_transactional_fixtures = true
  config.filter_rails_from_backtrace!

  # ===== ここから追加する設定 =====

  config.include FactoryBot::Syntax::Methods

  config.include LoginMacros, type: :system
  config.include LoginMacros, type: :request

  config.before(:suite) do
    Rails.application.load_seed if Category.count.zero?
  end

  # ===== CI環境用の設定 =====

  if ENV['CI'] || ENV['GITHUB_ACTIONS']
    config.filter_run_excluding type: :system
    puts "CI環境: Systemテストをスキップしています"
  end

  # ===== CI環境用の設定ここまで =====
end
