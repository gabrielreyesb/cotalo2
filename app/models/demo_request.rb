class DemoRequest < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :company, presence: true
  validates :message, presence: true, length: { minimum: 10 }
end
