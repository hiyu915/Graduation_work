require "carrierwave/storage/abstract"
require "carrierwave/storage/file"
require "carrierwave/storage/fog"

CarrierWave.configure do |config|
  # 共通設定（AWS認証情報）
  config.fog_credentials = {
    provider: "AWS",
    aws_access_key_id: ENV["S3_ACCESS_KEY_ID"],
    aws_secret_access_key: ENV["S3_SECRET_ACCESS_KEY"],
    region: ENV["S3_REGION"]
  }
  config.fog_directory  = ENV["S3_BUCKET_NAME"]
  config.fog_public = false

  # ★ローカルでも S3 にアップしたい場合はこちら
  if Rails.env.development? || Rails.env.production?
    config.storage = :fog
  else
    config.storage = :file
    config.enable_processing = false if Rails.env.test?
  end
end