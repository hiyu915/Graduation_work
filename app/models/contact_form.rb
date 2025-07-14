class ContactForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string
  attribute :category, :string
  attribute :message, :string

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :category, presence: true
  validates :message, presence: true, length: { maximum: 2000 }
end
