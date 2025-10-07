class AvatarUploader < CarrierWave::Uploader::Base
  if Rails.env.development? # 開発環境の場合
    storage :file
  elsif Rails.env.test? # テスト環境の場合
    storage :file
  else # 本番環境の場合
    storage :fog
  end
end
