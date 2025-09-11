class User < ApplicationRecord
  authenticates_with_sorcery!

  # before_create :setup_activation

  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 3 }, if: -> { new_record? || password.present? }
  validates :password, confirmation: true, if: -> { new_record? || password.present? }
  validates :password_confirmation, presence: true, if: -> { new_record? || password.present? }
  validates :reset_password_token, uniqueness: true, allow_nil: true
  validates :email_change_token, uniqueness: true, allow_nil: true
  validates :unconfirmed_email, uniqueness: true, allow_nil: true

  has_many :posts, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_posts, through: :favorites, source: :post
  has_many :visits, dependent: :destroy
  has_many :authentications, dependent: :destroy
  accepts_nested_attributes_for :authentications

  def generate_email_change_token!(new_email)
    self.unconfirmed_email = new_email
    self.email_change_token = SecureRandom.urlsafe_base64
    self.email_change_token_expires_at = 2.hours.from_now
    save!
  end

  def email_change_token_valid?(token)
    self.email_change_token == token &&
      email_change_token_expires_at.present? &&
      email_change_token_expires_at.future?
  end

  def confirm_email_change!
    self.email = self.unconfirmed_email
    self.unconfirmed_email = nil
    self.email_change_token = nil
    self.email_change_token_expires_at = nil
    save!
  end
end
