class SuggestionsController < ApplicationController
  def create
    @suggestion = Suggestion.new(suggestion_params.merge(user: current_user))
    
    if @suggestion.save
      AdminMailer.new_suggestion_notification(@suggestion).deliver_later
      flash[:notice] = "¡Gracias por tu sugerencia! La revisaremos pronto."
    else
      flash[:alert] = "No se pudo guardar la sugerencia. Por favor, inténtalo de nuevo."
    end
    
    redirect_back(fallback_location: root_path)
  end

  def index
    @suggestions = current_user.suggestions.order(created_at: :desc)
  end

  def edit
    @suggestion = current_user.suggestions.find(params[:id])
  end

  def update
    @suggestion = current_user.suggestions.find(params[:id])
    if @suggestion.update(suggestion_params)
      redirect_to suggestions_path, notice: "Sugerencia actualizada correctamente."
    else
      render :edit
    end
  end

  private

  def suggestion_params
    params.require(:suggestion).permit(:content)
  end
end 