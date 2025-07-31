class Shop < ApplicationRecord
  has_many :posts, dependent: :restrict_with_error
  belongs_to :location

  validates :location_id, presence: true
  validates :name, presence: true

  def self.ransackable_attributes(auth_object = nil)
    super + ['name']
  end

  def self.ransackable_associations(auth_object = nil)
    super + ['location']
  end
end
