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
      # Create subscription using Stripe
      subscription = current_user.create_subscription(ENV['STRIPE_PRICE_ID'])
      
      if subscription
        redirect_to subscription_path, notice: 'Suscripción creada exitosamente.'
      else
        redirect_to new_subscription_path, alert: 'Error al crear la suscripción. Por favor, inténtalo de nuevo.'
      end
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error creating subscription: #{e.message}"
      redirect_to new_subscription_path, alert: "Error de pago: #{e.message}"
    rescue => e
      Rails.logger.error "Error creating subscription: #{e.message}"
      redirect_to new_subscription_path, alert: 'Error inesperado. Por favor, inténtalo de nuevo.'
    end
  end

  def create_checkout_session
    begin
      # Ensure user has a Stripe customer
      current_user.create_stripe_customer if current_user.stripe_customer_id.blank?

      # Create Stripe checkout session
      session = Stripe::Checkout::Session.create(
        customer: current_user.stripe_customer_id,
        payment_method_types: ['card'],
        line_items: [{
          price: ENV['STRIPE_PRICE_ID'],
          quantity: 1,
        }],
        mode: 'subscription',
        success_url: subscription_url + '?session_id={CHECKOUT_SESSION_ID}',
        cancel_url: new_subscription_url,
        metadata: {
          user_id: current_user.id
        }
      )

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
    # This method ensures the user has a subscription to manage
    unless current_user.stripe_subscription_id.present?
      redirect_to new_subscription_path, alert: 'No tienes una suscripción activa.'
    end
  end
end 