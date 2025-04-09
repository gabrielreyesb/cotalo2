class SuggestionsController < ApplicationController
  def create
    @suggestion = Suggestion.new(
      content: params[:suggestion],
      user: current_user
    )
    
    if @suggestion.save
      flash[:notice] = "¡Gracias por tu sugerencia! La revisaremos pronto."
    else
      flash[:alert] = "No se pudo guardar la sugerencia. Por favor, inténtalo de nuevo."
    end
    
    redirect_back(fallback_location: root_path)
  end
end 