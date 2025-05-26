class User < ApplicationRecord
  authenticates_with_sorcery!

  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 3 }, if: -> { new_record? || password.present? }
  validates :password, confirmation: true, if: -> { new_record? || password.present? }
  validates :password_confirmation, presence: true, if: -> { new_record? || password.present? }
  
  has_many :posts, dependent: :destroy
  #has_many :favorites, dependent: :destroy
  #has_many :favorite_posts, through: :favorites, source: :post
  #has_many :visits, dependent: :destroy
end
