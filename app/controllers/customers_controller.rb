class CustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_customer, only: [:show, :edit, :update, :destroy]

  def index
    @customers = current_user.customers.order(name: :asc)
  end

  def show
  end

  def new
    @customer = current_user.customers.build
  end

  def edit
  end

  def create
    @customer = current_user.customers.build(customer_params)

    respond_to do |format|
      if @customer.save
        format.html { redirect_to customers_path, notice: t('customers.create.success') }
        format.json { render :show, status: :created, location: @customer }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to customers_path, notice: t('customers.update.success') }
        format.json { render :show, status: :ok, location: @customer }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @customer.destroy
    respond_to do |format|
      format.html { redirect_to customers_url, notice: t('customers.destroy.success') }
      format.json { head :no_content }
    end
  end

  private

  def set_customer
    @customer = current_user.customers.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:name, :email, :phone, :company, :address, :notes)
  end
end 