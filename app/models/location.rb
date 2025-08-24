class Location < ApplicationRecord
  belongs_to :prefecture
  belongs_to :city
  has_many :shops

  validates :prefecture_id, presence: true
  validates :city_id, presence: true

  # Geocoder 用設定
  geocoded_by :full_address
  after_validation :geocode, if: ->(obj) { obj.prefecture_id_changed? || obj.city_id_changed? }

  # 都道府県 + 市からフル住所を生成
  def full_address
    [prefecture&.name, city&.name].compact.join
  end

  # Ransack 検索対応
  def self.ransackable_attributes(auth_object = nil)
    super + ["name"]
  end
end
