class Post < ApplicationRecord
  validates :shop_name, presence: true
  validates :visited_at, presence: true
  # validates :visit_date, presence: true
  # validates :category_id, presence: true
  # validates :feeling_id, presence: true
  # validates :companion_id, presence: true
  # validates :visit_reason_id, presence: true
  # validates :prefecture_id, presence: true
  # validates :city_id, presence: true

  belongs_to :user
  # belongs_to :category
  # belongs_to :feeling
  # belongs_to :companion
  # belongs_to :visit_reason
  # belongs_to :prefecture
  # belongs_to :city

  # has_many :favorites, dependent: :destroy
  # has_many :favorited_users, through: :favorites, source: :user

  # has_many :visits, dependent: :destroy
  # has_many :calendar_records, dependent: :destroy
end
