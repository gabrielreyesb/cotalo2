class Customer < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :phone, presence: true, allow_nil: true
  validates :user, presence: true

  # Scope to find customers belonging to a specific user
  scope :for_user, ->(user) { where(user: user) }
end 