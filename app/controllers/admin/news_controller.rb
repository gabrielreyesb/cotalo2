class Admin::NewsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_news, only: [:show, :edit, :update, :destroy, :send_email]
  layout 'application'

  def index
    @news = News.recent
  end

  def show
  end

  def new
    @news = News.new
  end

  def edit
  end

  def create
    @news = News.new(news_params)

    if @news.save
      redirect_to admin_news_index_path, notice: 'Noticia creada exitosamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @news.update(news_params)
      redirect_to admin_news_index_path, notice: 'Noticia actualizada exitosamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @news.destroy
    redirect_to admin_news_index_path, notice: 'Noticia eliminada exitosamente.'
  end

  def send_email
    begin
      # Get all active, non-admin users
      users = User.where(disabled: false, admin: false)
      
      if users.empty?
        redirect_to admin_news_index_path, alert: t('admin.news.no_active_users')
        return
      end

      # Send email to each user
      users.each do |user|
        NewsMailer.send_news_email(@news, user).deliver_later
      end

      # Mark the news as sent
      @news.update(sent_via_email: true, sent_at: Time.current)

      redirect_to admin_news_index_path, notice: t('admin.news.email_sent_success', count: users.count)
    rescue => e
      Rails.logger.error "Error sending news email: #{e.message}"
      redirect_to admin_news_index_path, alert: t('admin.news.email_sent_error')
    end
  end

  private

  def set_news
    @news = News.find(params[:id])
  end

  def news_params
    params.require(:news).permit(:title, :content, :published_at)
  end

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Acceso no autorizado.'
    end
  end
end 