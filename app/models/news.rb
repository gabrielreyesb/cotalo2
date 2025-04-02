class News < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true
  validates :published_at, presence: true
  
  # Scope to get the most recent news first
  scope :recent, -> { order(published_at: :desc) }
  
  # Scope to get only published news
  scope :published, -> { where('published_at <= ?', Time.current) }
  
  # Default published_at to current time if not set
  before_validation :set_default_published_at
  
  private
  
  def set_default_published_at
    self.published_at ||= Time.current
  end
end
