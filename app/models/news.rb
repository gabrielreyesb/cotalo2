class News < ApplicationRecord
  validates :title, presence: { message: "El título es requerido" }
  validates :content, presence: { message: "El contenido es requerido" }
  validates :published_at, presence: { message: "La fecha de publicación es requerida" }
  
  # Scope to get the most recent news first
  scope :recent, -> { order(published_at: :desc) }
  
  # Scope to get only published news
  scope :published, -> { where('published_at <= ?', Time.current) }
  
  # Scope to get news that haven't been sent via email
  scope :unsent, -> { where(sent_via_email: [false, nil]) }
  
  # Default published_at to current time if not set
  before_validation :set_default_published_at
  
  # Default sent_via_email to false
  after_initialize :set_default_sent_via_email, if: :new_record?
  
  private
  
  def set_default_published_at
    self.published_at ||= Time.current
  end
  
  def set_default_sent_via_email
    self.sent_via_email ||= false
  end
end
