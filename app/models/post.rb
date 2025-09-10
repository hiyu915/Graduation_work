class Post < ApplicationRecord
  # attr_accessor :shop_name

  validates :shop_name, presence: true, length: { maximum: 100 }
  # validates :shop_id, presence: true
  validates :visit_date, presence: true
  validates :category_id, presence: true
  validates :feeling_id, presence: true
  validates :companion_id, presence: true
  validates :visit_reason_id, presence: true
  validates :body, length: { maximum: 2000 }

  belongs_to :user
  belongs_to :category
  belongs_to :feeling
  belongs_to :companion
  belongs_to :visit_reason
  belongs_to :shop, optional: true

  has_many :visits, through: :shop
  has_many :favorites, dependent: :destroy
  has_many :favorited_users, through: :favorites, source: :user

  mount_uploader :post_image, PostImageUploader

  scope :latest_unique_by_shop_and_location, ->(sort_direction = "desc") do
    dir = sort_direction.to_s.downcase == "asc" ? "ASC" : "DESC"
    subquery = select("DISTINCT ON (shops.id, shops.location_id) posts.id")
      .joins(:shop)
      .order(Arel.sql("shops.id, shops.location_id, posts.visit_date #{dir}"))
    where(id: subquery)
  end

  scope :by_category, ->(category_id) { where(category_id: category_id) if category_id.present? }
  scope :recent, -> { order(visit_date: :desc) }

  scope :same_shop_and_location, ->(shop_id, location_id) {
    joins(:shop).where(shops: { id: shop_id, location_id: location_id }).order(visit_date: :desc)
  }

  def favorited_by?(user)
    favorites.exists?(user_id: user.id)
  end

  def visited_by_user?(user)
    shop.visits.exists?(user_id: user.id)
  end

  def self.search(query)
    return all if query.blank?

    q = "%#{sanitize_sql_like(query)}%"
    left_joins(:shop)
      .where("posts.body ILIKE :q OR posts.shop_name ILIKE :q OR shops.name ILIKE :q", q: q)
  end

  def display_shop_name
    shop_name.presence || shop&.name
  end

  def self.ransackable_attributes(auth_object = nil)
    super + [
      "visit_date", "category_id", "companion_id", "feeling_id", "visit_reason_id",
      "body", "shop_id", "shop_location_prefecture_id", "shop_location_city_id"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    super + [ "shop" ]
  end

  # 仮想属性（ransacker）
  ransacker :shop_location_prefecture_id, type: :integer do
    Arel.sql(<<~SQL.squish)
      (
        SELECT locations.prefecture_id
        FROM shops
        JOIN locations ON locations.id = shops.location_id
        WHERE shops.id = posts.shop_id
        LIMIT 1
      )
    SQL
  end

  ransacker :shop_location_city_id, type: :integer do
    Arel.sql(<<~SQL.squish)
      (
        SELECT locations.city_id
        FROM shops
        JOIN locations ON locations.id = shops.location_id
        WHERE shops.id = posts.shop_id
        LIMIT 1
      )
    SQL
  end

  before_save :assign_shop_id_from_name

  private

  def assign_shop_id_from_name
    if shop_name.present? && shop_id.blank?
      shop = Shop.find_or_create_by(name: shop_name) do |s|
        s.location_id = Location.first&.id || Location.create!(prefecture_id: 1, city_id: 1).id
      end
      # puts "assign_shop_id_from_name called: shop.id=#{shop.id}, shop.name=#{shop.name}"
      self.shop_id = shop.id
    end
  end
end
