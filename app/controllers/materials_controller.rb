class MaterialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_material, only: [:show, :edit, :update, :destroy]

  def index
    @materials = current_user.materials.includes(:unit)
  end

  def show
  end

  def new
    @material = current_user.materials.build
  end

  def edit
  end

  def create
    @material = current_user.materials.build(material_params)

    respond_to do |format|
      if @material.save
        format.html { redirect_to materials_path, notice: 'Material was successfully created.' }
        format.json { render :show, status: :created, location: @material }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @material.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @material.update(material_params)
        format.html { redirect_to materials_path, notice: 'Material was successfully updated.' }
        format.json { render :show, status: :ok, location: @material }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @material.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @material.destroy
    respond_to do |format|
      format.html { redirect_to materials_url, notice: 'Material was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_material
    @material = current_user.materials.find(params[:id])
  end

  def material_params
    params.require(:material).permit(:description, :price, :nombre, :especificaciones, :ancho, :largo, :comments, :unit_id)
  end
end
