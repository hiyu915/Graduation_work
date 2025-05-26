class Shop < ApplicationRecord
  has_many :posts, dependent: :restrict_with_error
  belongs_to :location

	validates :location_id, presence: true
  validates :name, presence: true
end
