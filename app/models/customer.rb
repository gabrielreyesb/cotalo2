class Customer < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :user, presence: true

  # Scope to find customers belonging to a specific user
  scope :for_user, ->(user) { where(user: user) }
end 