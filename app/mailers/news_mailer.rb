class NewsMailer < ApplicationMailer
  def send_news_email(news, user)
    @news = news
    @user = user
    
    mail(
      to: @user.email,
      subject: "Novedad: #{@news.title}"
    )
  end
end 