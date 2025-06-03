module ApplicationHelper
  def render_pagination(collection)
    render partial: 'shared/pagination', locals: { collection: collection }
  end
end
