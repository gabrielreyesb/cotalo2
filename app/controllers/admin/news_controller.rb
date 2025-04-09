class Admin::NewsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_news, only: [:show, :edit, :update, :destroy]
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
      redirect_to admin_news_path(@news), notice: 'Noticia creada exitosamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @news.update(news_params)
      redirect_to admin_news_path(@news), notice: 'Noticia actualizada exitosamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @news.destroy
    redirect_to admin_news_index_path, notice: 'Noticia eliminada exitosamente.'
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