class PostImageUploader < CarrierWave::Uploader::Base
  # S3を使用するための設定に変更
  storage :fog  # ← file から fog に変更

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def default_url
    "/images/post_placeholder.png"
  end

  def extension_allowlist
    %w[jpg jpeg gif png]
  end
end