class PostImageUploader < CarrierWave::Uploader::Base
  storage :fog

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