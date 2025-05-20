module Admin
  class SuggestionsController < ::AdminController
    def index
      @suggestions = Suggestion.recent.includes(:user)
    end

    def update
      @suggestion = Suggestion.find(params[:id])
      if @suggestion.update(admin_comment: params[:suggestion][:admin_comment], reviewed: true)
        flash[:notice] = "Sugerencia marcada como revisada y comentario guardado"
      else
        flash[:alert] = "No se pudo actualizar la sugerencia"
      end
      redirect_to admin_suggestions_path
    end
  end
end 