class ManufacturingProcessesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_manufacturing_process, only: [:show, :edit, :update, :destroy, :duplicate]
  before_action :no_cache, only: [:index, :show]

  def index
    # Clear any potential AR cache to ensure fresh data
    ActiveRecord::Base.connection.clear_query_cache
    
    @manufacturing_processes = current_user.manufacturing_processes.includes(:unit).order(name: :asc)
    if params[:q].present?
      query = "%#{params[:q]}%"
      adapter = ActiveRecord::Base.connection.adapter_name.downcase
      if adapter.include?("sqlite")
        @manufacturing_processes = @manufacturing_processes.where("name LIKE ? OR description LIKE ?", query, query)
      else
        @manufacturing_processes = @manufacturing_processes.where("name ILIKE ? OR description ILIKE ?", query, query)
      end
    end
    @manufacturing_processes = @manufacturing_processes.page(params[:page]).per(10)
  end

  def show
    # Reload the record to ensure we have the latest data
    @manufacturing_process.reload
    
    # Debug logs
    puts "SHOW - MANUFACTURING PROCESS:"
    puts "  ID: #{@manufacturing_process.id}, Name: #{@manufacturing_process.name}, Unit ID: #{@manufacturing_process.unit_id}, Unit: #{@manufacturing_process.unit&.name || 'None'}"
  end

  def new
    @manufacturing_process = current_user.manufacturing_processes.build
  end

  def edit
  end

  def create
    @manufacturing_process = current_user.manufacturing_processes.build(manufacturing_process_params)

    respond_to do |format|
      if @manufacturing_process.save
        format.html { redirect_to manufacturing_processes_path, notice: t('processes.create.success') }
        format.json { render :show, status: :created, location: @manufacturing_process }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @manufacturing_process.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    # Debug logs
    puts "PARAMS: #{params.inspect}"
    puts "MANUFACTURING PROCESS PARAMS: #{manufacturing_process_params.inspect}"
    puts "BEFORE UPDATE - PROCESS UNIT ID: #{@manufacturing_process.unit_id}"
    
    respond_to do |format|
      if @manufacturing_process.update(manufacturing_process_params)
        puts "AFTER UPDATE - PROCESS UNIT ID: #{@manufacturing_process.unit_id}"
        format.html { redirect_to manufacturing_processes_path, notice: t('processes.update.success') }
        format.json { render :show, status: :ok, location: @manufacturing_process }
      else
        puts "UPDATE FAILED - ERRORS: #{@manufacturing_process.errors.full_messages}"
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @manufacturing_process.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @manufacturing_process.destroy
    respond_to do |format|
      format.html { redirect_to manufacturing_processes_url }
      format.json { head :no_content }
    end
  end

  def duplicate
    @new_process = @manufacturing_process.dup
    @new_process.name = "#{@manufacturing_process.name} (Copia)"
    
    if @new_process.save
      redirect_to manufacturing_processes_path
    else
      redirect_to manufacturing_processes_path, alert: 'Error duplicating process.'
    end
  end

  private

  def set_manufacturing_process
    @manufacturing_process = current_user.manufacturing_processes.find(params[:id])
  end

  def manufacturing_process_params
    # Debug parameters 
    puts "RAW PARAMS: #{params.inspect}"
    params.require(:manufacturing_process).permit(:name, :description, :cost, :unit_id, :side)
  end

  def no_cache
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
