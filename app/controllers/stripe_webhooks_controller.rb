class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  def create
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = Rails.configuration.stripe[:signing_secret]

    # Log the raw payload for debugging
    Rails.logger.info "[STRIPE WEBHOOK] Raw payload: #{payload}"

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
      # Log the event type
      Rails.logger.info "[STRIPE WEBHOOK] Event type: #{event.type}"
    rescue JSON::ParserError => e
      # Invalid payload
      Rails.logger.error "Invalid payload: #{e.message}"
      head :bad_request
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature
      Rails.logger.error "Invalid signature: #{e.message}"
      head :bad_request
      return
    end

    # Handle the event
    case event.type
    when 'customer.subscription.created'
      handle_subscription_created(event.data.object)
    when 'customer.subscription.updated'
      handle_subscription_updated(event.data.object)
    when 'customer.subscription.deleted'
      handle_subscription_deleted(event.data.object)
    when 'invoice.payment_succeeded'
      handle_payment_succeeded(event.data.object)
    when 'invoice.payment_failed'
      handle_payment_failed(event.data.object)
    else
      Rails.logger.info "Unhandled event type: #{event.type}"
    end

    head :ok
  end

  private

  def handle_subscription_created(subscription)
    user = User.find_by(stripe_customer_id: subscription.customer)
    return unless user

    user.update(
      stripe_subscription_id: subscription.id,
      subscription_status: subscription.status,
      subscription_plan: subscription.items.data.first.price.id,
      subscription_ends_at: Time.at(subscription.current_period_end)
    )

    # Send welcome email for new subscription
    SubscriptionMailer.subscription_welcome(user).deliver_later
  end

  def handle_subscription_updated(subscription)
    user = User.find_by(stripe_customer_id: subscription.customer)
    return unless user

    user.update(
      subscription_status: subscription.status,
      subscription_ends_at: Time.at(subscription.current_period_end)
    )

    # Handle subscription status changes
    case subscription.status
    when 'past_due'
      SubscriptionMailer.subscription_past_due(user).deliver_later
    when 'canceled'
      SubscriptionMailer.subscription_canceled(user).deliver_later
    end
  end

  def handle_subscription_deleted(subscription)
    user = User.find_by(stripe_customer_id: subscription.customer)
    return unless user

    user.update(
      subscription_status: 'expired',
      subscription_ends_at: Time.at(subscription.ended_at)
    )

    SubscriptionMailer.subscription_expired(user).deliver_later
  end

  def handle_payment_succeeded(invoice)
    user = User.find_by(stripe_customer_id: invoice.customer)
    return unless user

    # Extract only the necessary data from the invoice
    invoice_data = {
      id: invoice.id,
      amount_paid: invoice.amount_paid,
      currency: invoice.currency,
      status: invoice.status,
      created: invoice.created
    }

    SubscriptionMailer.payment_succeeded(user, invoice_data).deliver_later
  end

  def handle_payment_failed(invoice)
    user = User.find_by(stripe_customer_id: invoice.customer)
    return unless user

    # Extract only the necessary data from the invoice
    invoice_data = {
      id: invoice.id,
      amount_due: invoice.amount_due,
      currency: invoice.currency,
      status: invoice.status,
      created: invoice.created
    }

    SubscriptionMailer.payment_failed(user, invoice_data).deliver_later
  end
end 