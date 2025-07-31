class Post < ApplicationRecord
  validates :shop_id, presence: true
  validates :visit_date, presence: true
  validates :category_id, presence: true
  validates :feeling_id, presence: true
  validates :companion_id, presence: true
  validates :visit_reason_id, presence: true

  belongs_to :user
  belongs_to :category
  belongs_to :feeling
  belongs_to :companion
  belongs_to :visit_reason
  belongs_to :shop

  has_many :favorites, dependent: :destroy
  has_many :favorited_users, through: :favorites, source: :user

  mount_uploader :post_image, PostImageUploader

  scope :latest_unique_by_shop_and_location, -> {
    select("DISTINCT ON (shops.id, shops.location_id) posts.*")
      .joins(:shop)
      .order("shops.id, shops.location_id, posts.visit_date DESC")
  }

  scope :same_shop_and_location, ->(shop_id, location_id) {
    joins(:shop).where(shops: { id: shop_id, location_id: location_id }).order(visit_date: :desc)
  }


  def self.ransackable_attributes(auth_object = nil)
    super + [
      "visit_date", "category_id", "companion_id", "feeling_id", "visit_reason_id",
      "body", "shop_id", "shop_location_prefecture_id", "shop_location_id"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    super + [ "shop" ]
  end

  # 仮想属性（ransacker）
  ransacker :shop_location_prefecture_id, type: :integer do
    Arel.sql("(SELECT locations.prefecture_id FROM shops JOIN locations ON locations.id = shops.location_id WHERE shops.id = posts.shop_id)")
  end

  ransacker :shop_location_id, type: :integer do
    Arel.sql("(SELECT locations.city_id FROM shops JOIN locations ON locations.id = shops.location_id WHERE shops.id = posts.shop_id)")
  end
end
