class MaterialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_material, only: [:show, :edit, :update, :destroy, :duplicate]

  def index
    @materials = current_user.materials.includes(:unit).order(description: :asc)
    if params[:q].present?
      query = "%#{params[:q]}%"
      adapter = ActiveRecord::Base.connection.adapter_name.downcase
      if adapter.include?("sqlite")
        @materials = @materials.where("description LIKE ? OR client_description LIKE ?", query, query)
      else
        @materials = @materials.where("description ILIKE ? OR client_description ILIKE ?", query, query)
      end
    end
    @materials = @materials.page(params[:page]).per(10)
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
        format.html { redirect_to materials_path, notice: t('materials.create.success') }
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
        format.html { redirect_to materials_path, notice: t('materials.update.success') }
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
      format.html { redirect_to materials_url }
      format.json { head :no_content }
    end
  end

  def duplicate
    @new_material = @material.dup
    @new_material.description = "#{@material.description} (Copia)"
    @new_material.client_description = "#{@material.client_description} (Copia)"
    
    if @new_material.save
      redirect_to materials_path
    else
      redirect_to materials_path, alert: 'Error duplicating material.'
    end
  end

  private

  def set_material
    @material = current_user.materials.find(params[:id])
  end

  def material_params
    params.require(:material).permit(:description, :price, :client_description, :resistance, :ancho, :largo, :comments, :unit_id)
  end
end
