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
    select('DISTINCT ON (shops.id, shops.location_id) posts.*')
      .joins(:shop)
      .order('shops.id, shops.location_id, posts.visit_date DESC')
  }

  scope :same_shop_and_location, ->(shop_id, location_id) {
    joins(:shop).where(shops: { id: shop_id, location_id: location_id }).order(visit_date: :desc)
  }
end
