class UnitsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_unit, only: [:show, :edit, :update, :destroy]

  def index
    @units = current_user.units
  end

  def show
  end

  def new
    @unit = current_user.units.build
  end

  def edit
  end

  def create
    @unit = current_user.units.build(unit_params)

    respond_to do |format|
      if @unit.save
        format.html { redirect_to units_path, notice: 'Unit was successfully created.' }
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
        format.html { redirect_to units_path, notice: 'Unit was successfully updated.' }
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
        format.html { redirect_to units_url, notice: 'Unit was successfully destroyed.' }
        format.json { head :no_content }
      else
        format.html { redirect_to units_url, alert: 'Cannot delete unit that is being used by materials.' }
        format.json { render json: { error: 'Cannot delete unit that is being used by materials.' }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_unit
    @unit = current_user.units.find(params[:id])
  end

  def unit_params
    params.require(:unit).permit(:name, :abbreviation)
  end
end
