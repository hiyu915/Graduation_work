class Location < ApplicationRecord
  belongs_to :prefecture
  belongs_to :city
  has_many :shops
  
  validates :prefecture_id, presence: true
  validates :city_id, presence: true
end
