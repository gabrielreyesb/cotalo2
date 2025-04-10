class Admin::UnitsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_unit, only: [:show, :edit, :update, :destroy]

  def index
    @units = Unit.all.order(:name)
  end

  def show
  end

  def new
    @unit = Unit.new
  end

  def edit
  end

  def create
    @unit = Unit.new(unit_params)

    respond_to do |format|
      if @unit.save
        format.html { redirect_to admin_units_path }
        format.json { render :show, status: :created, location: @unit }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @unit.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @unit.update(unit_params)
        format.html { redirect_to admin_units_path }
        format.json { render :show, status: :ok, location: @unit }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @unit.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @unit.destroy
        format.html { redirect_to admin_units_url }
        format.json { head :no_content }
      else
        format.html { redirect_to admin_units_url, alert: 'No se puede eliminar una unidad que está siendo utilizada por materiales.' }
        format.json { render json: { error: 'No se puede eliminar una unidad que está siendo utilizada por materiales.' }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_unit
    @unit = Unit.find(params[:id])
  end

  def unit_params
    params.require(:unit).permit(:name, :abbreviation)
  end

  def require_admin
    unless current_user&.admin?
      flash[:alert] = "No tienes permiso para acceder a esta sección"
      redirect_to root_path
    end
  end
end 