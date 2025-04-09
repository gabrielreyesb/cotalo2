module Admin
  class SuggestionsController < ::AdminController
    def index
      @suggestions = Suggestion.recent.includes(:user)
    end

    def update
      @suggestion = Suggestion.find(params[:id])
      if @suggestion.update(reviewed: true)
        flash[:notice] = "Sugerencia marcada como revisada"
      else
        flash[:alert] = "No se pudo actualizar la sugerencia"
      end
      redirect_to admin_suggestions_path
    end
  end
end 