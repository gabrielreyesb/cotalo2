class NewsController < ApplicationController
  def index
    @news = News.published.recent
  end
end
