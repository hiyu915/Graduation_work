class User < ApplicationRecord
  authenticates_with_sorcery!

  # ❌ 外部認証時はアクティベーション不要なのでコメントアウト
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

  def self.create_from_provider(provider_name, uid, user_info)
    Rails.logger.info "=== Google認証デバッグ ==="
    Rails.logger.info "provider: #{provider_name}, uid: #{uid}, email: #{user_info['email']}"

    # 1. 既存の認証情報をチェック
    authentication = Authentication.find_by(provider: provider_name, uid: uid)
    if authentication
      Rails.logger.info "既存認証情報でログイン: #{authentication.user.email}"
      return authentication.user
    end

    # 2. 同じメールアドレスのユーザーをチェック
    user = User.find_by(email: user_info['email'])
    if user
      user.authentications.create!(provider: provider_name, uid: uid)
      Rails.logger.info "既存ユーザーに認証情報を追加: #{user.email}"
      return user
    end

    # 3. 新規ユーザー作成（外部認証専用）
    user = User.new(email: user_info['email'])
    user.password = SecureRandom.hex(10)
    user.password_confirmation = user.password
    
    # 🎯 外部認証の場合は最初からアクティブにして、メール送信を回避
    user.activation_state = 'active' if user.respond_to?(:activation_state)
    user.skip_activation_needed_email! if user.respond_to?(:skip_activation_needed_email!)
    
    if user.save
      user.authentications.create!(provider: provider_name, uid: uid)
      Rails.logger.info "新規ユーザー作成成功: #{user.email}"
      return user
    else
      Rails.logger.error "Google認証でのユーザー作成に失敗: #{user.errors.full_messages}"
      return nil
    end
  end

  private

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

  # 通常のユーザー登録時のみアクティベーション設定
  def setup_activation
    if respond_to?(:activation_state) && activation_state.blank?
      self.activation_state = 'pending'
    end
  end
end