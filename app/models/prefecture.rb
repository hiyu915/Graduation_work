class Prefecture < ApplicationRecord
  has_many :locations

  validates :name, presence: true, uniqueness: true
end
