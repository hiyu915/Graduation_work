class Category < ApplicationRecord
  has_many :posts
  has_many :shops, dependent: :restrict_with_error
  validates :name, presence: true, uniqueness: true
end
