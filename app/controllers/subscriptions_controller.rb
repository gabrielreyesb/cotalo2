class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subscription, only: [:show, :update, :destroy]

  def new
    # Check if user already has an active subscription
    if current_user.active_subscription?
      redirect_to subscription_path, notice: 'Ya tienes una suscripción activa.'
      return
    end
  end

  def create
    begin
      Rails.logger.info "=== DEBUG: Starting subscription creation with payment method ==="
      
      # Check if request is JSON (from Stripe Elements) or form data
      if request.content_type == 'application/json'
        payment_method_id = JSON.parse(request.body.read)['payment_method_id']
        Rails.logger.info "=== DEBUG: Payment method ID received: #{payment_method_id}"
      else
        # Fallback for form data (should not happen with new implementation)
        redirect_to new_subscription_path, alert: 'Método de pago no válido.'
        return
      end
      
      # Ensure user has a Stripe customer
      current_user.create_stripe_customer if current_user.stripe_customer_id.blank?
      Rails.logger.info "=== DEBUG: Customer ID: #{current_user.stripe_customer_id}"
      
      # Attach payment method to customer
      Stripe::PaymentMethod.attach(
        payment_method_id,
        { customer: current_user.stripe_customer_id }
      )
      Rails.logger.info "=== DEBUG: Payment method attached to customer"
      
      # Set as default payment method
      Stripe::Customer.update(
        current_user.stripe_customer_id,
        { invoice_settings: { default_payment_method: payment_method_id } }
      )
      Rails.logger.info "=== DEBUG: Payment method set as default"
      
      # Create subscription
      subscription = current_user.create_subscription(ENV['STRIPE_PRICE_ID'])
      
      if subscription
        Rails.logger.info "=== DEBUG: Subscription created successfully: #{subscription.id} ==="
        render json: { success: true, subscription_id: subscription.id }
      else
        Rails.logger.error "=== DEBUG: Failed to create subscription ==="
        render json: { success: false, error: 'Error al crear la suscripción.' }, status: :unprocessable_entity
      end
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error creating subscription: #{e.message}"
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "Error creating subscription: #{e.message}"
      render json: { success: false, error: 'Error inesperado. Por favor, inténtalo de nuevo.' }, status: :unprocessable_entity
    end
  end

  def create_checkout_session
    begin
      Rails.logger.info "=== DEBUG: Starting checkout session creation ==="
      Rails.logger.info "=== DEBUG: Stripe API Key: #{Stripe.api_key[0..20]}..." if Stripe.api_key
      Rails.logger.info "=== DEBUG: Price ID: #{ENV['STRIPE_PRICE_ID']}"
      Rails.logger.info "=== DEBUG: User ID: #{current_user.id}"
      
      # Ensure user has a Stripe customer
      current_user.create_stripe_customer if current_user.stripe_customer_id.blank?
      Rails.logger.info "=== DEBUG: Customer ID: #{current_user.stripe_customer_id}"

      # Create Stripe checkout session with billing_address_collection
      Rails.logger.info "=== DEBUG: Creating Stripe checkout session ==="
      session = Stripe::Checkout::Session.create(
        customer: current_user.stripe_customer_id,
        payment_method_types: ['card'],
        line_items: [{
          price: ENV['STRIPE_PRICE_ID'],
          quantity: 1,
        }],
        mode: 'subscription',
        billing_address_collection: 'required',
        success_url: subscription_url + '?session_id={CHECKOUT_SESSION_ID}',
        cancel_url: new_subscription_url,
        metadata: {
          user_id: current_user.id
        }
      )
      Rails.logger.info "=== DEBUG: Session created successfully: #{session.id}"

      render json: { id: session.id }
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error creating checkout session: #{e.message}"
      render json: { error: e.message }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "Error creating checkout session: #{e.message}"
      render json: { error: 'Error inesperado' }, status: :unprocessable_entity
    end
  end

  def show
    Rails.logger.info "=== DEBUG: User accessing subscription page ==="
    Rails.logger.info "Current user: #{current_user.email}"
    Rails.logger.info "Customer ID: #{current_user.stripe_customer_id}"
    Rails.logger.info "Subscription ID: #{current_user.stripe_subscription_id}"
    Rails.logger.info "Subscription status: #{current_user.subscription_status}"
    Rails.logger.info "Created at: #{current_user.created_at}"
    Rails.logger.info "Subscription ends at: #{current_user.subscription_ends_at}"
    
    # Update subscription status from Stripe
    if current_user.stripe_subscription_id.present?
      current_user.update_subscription_status
    end
  end

  def update
    begin
      case params[:action_type]
      when 'reactivate'
        subscription = current_user.reactivate_subscription
        if subscription
          redirect_to subscription_path, notice: 'Suscripción reactivada exitosamente.'
        else
          redirect_to subscription_path, alert: 'Error al reactivar la suscripción.'
        end
      when 'update_payment'
        # Redirect to Stripe Customer Portal for payment method update
        portal_session = Stripe::BillingPortal::Session.create(
          customer: current_user.stripe_customer_id,
          return_url: subscription_url
        )
        redirect_to portal_session.url, allow_other_host: true
      else
        redirect_to subscription_path, alert: 'Acción no válida.'
      end
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error updating subscription: #{e.message}"
      redirect_to subscription_path, alert: "Error de pago: #{e.message}"
    rescue => e
      Rails.logger.error "Error updating subscription: #{e.message}"
      redirect_to subscription_path, alert: 'Error inesperado. Por favor, inténtalo de nuevo.'
    end
  end

  def destroy
    begin
      subscription = current_user.cancel_subscription
      if subscription
        redirect_to subscription_path, notice: 'Suscripción cancelada exitosamente. Podrás seguir usando Cotalo hasta el final del período actual.'
      else
        redirect_to subscription_path, alert: 'Error al cancelar la suscripción.'
      end
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error canceling subscription: #{e.message}"
      redirect_to subscription_path, alert: "Error de pago: #{e.message}"
    rescue => e
      Rails.logger.error "Error canceling subscription: #{e.message}"
      redirect_to subscription_path, alert: 'Error inesperado. Por favor, inténtalo de nuevo.'
    end
  end

  private

  def set_subscription
    # Allow users to view subscription page if they have a subscription or are in trial
    unless current_user.stripe_subscription_id.present? || current_user.trial?
      redirect_to new_subscription_path, alert: 'No tienes una suscripción activa.'
    end
  end
end 