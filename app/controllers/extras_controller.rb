class ExtrasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_extra, only: [:show, :edit, :update, :destroy, :duplicate]
  before_action :no_cache, only: [:index, :show]

  def index
    # Clear any potential AR cache to ensure fresh data
    ActiveRecord::Base.connection.clear_query_cache
    
    @extras = current_collection.includes(:unit).order(name: :asc)
    if params[:q].present?
      query = "%#{params[:q]}%"
      adapter = ActiveRecord::Base.connection.adapter_name.downcase
      if adapter.include?("sqlite")
        @extras = @extras.where("name LIKE ? OR description LIKE ?", query, query)
      else
        @extras = @extras.where("name ILIKE ? OR description ILIKE ?", query, query)
      end
    end
    @extras = @extras.page(params[:page]).per(10)
    
    # Debug logs
    puts "INDEX - EXTRAS:"
    @extras.each do |extra|
      puts "  ID: #{extra.id}, Name: #{extra.name}, Unit ID: #{extra.unit_id}, Unit: #{extra.unit&.name || 'None'}"
    end
  end

  def show
    # Reload the record to ensure we have the latest data
    @extra.reload
    
    # Debug logs
    puts "SHOW - EXTRA:"
    puts "  ID: #{@extra.id}, Name: #{@extra.name}, Unit ID: #{@extra.unit_id}, Unit: #{@extra.unit&.name || 'None'}"
  end

  def new
    @extra = current_collection.build
  end

  def edit
  end

  def create
    @extra = current_collection.build(extra_params)

    respond_to do |format|
      if @extra.save
        format.html { redirect_to current_collection_path }
        format.json { render :show, status: :created, location: @extra }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @extra.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    # Debug logs
    puts "PARAMS: #{params.inspect}"
    puts "EXTRA PARAMS: #{extra_params.inspect}"
    puts "BEFORE UPDATE - EXTRA UNIT ID: #{@extra.unit_id}"
    
    respond_to do |format|
      if @extra.update(extra_params)
        puts "AFTER UPDATE - EXTRA UNIT ID: #{@extra.unit_id}"
        format.html { redirect_to current_collection_path }
        format.json { render :show, status: :ok, location: @extra }
      else
        puts "UPDATE FAILED - ERRORS: #{@extra.errors.full_messages}"
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @extra.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @extra.destroy
    respond_to do |format|
      format.html { redirect_to current_collection_path }
      format.json { head :no_content }
    end
  end

  def duplicate
    @new_extra = @extra.dup
    @new_extra.name = "#{@extra.name} (Copia)"
    
    if @new_extra.save
      redirect_to current_collection_path
    else
      redirect_to current_collection_path, alert: 'Error duplicating extra.'
    end
  end

  private

  def set_extra
    @extra = current_collection.find(params[:id])
  end

  def extra_params
    # Debug parameters 
    puts "RAW PARAMS: #{params.inspect}"
    key = controller_name.singularize.to_sym
    params.require(key).permit(:name, :description, :cost, :unit_id)
  end
  
  def no_cache
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def current_collection
    # ExtrasController now only used via IndirectCostsController; fallback kept for safety
    controller_name == 'indirect_costs' ? current_user.indirect_costs : current_user.indirect_costs
  end

  def current_collection_path
    controller_name == 'indirect_costs' ? indirect_costs_path : indirect_costs_path
  end
end
