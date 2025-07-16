module StripeSubscription
  extend ActiveSupport::Concern

  included do
    # Callbacks
    after_create :create_stripe_customer
    after_update :update_stripe_customer, if: :saved_change_to_email?
    # Subscription status constants
    SUBSCRIPTION_STATUSES = %w[trial active past_due expired].freeze
  end

  def create_stripe_customer
    return if stripe_customer_id.present?

    customer = Stripe::Customer.create(
      email: email,
      metadata: {
        user_id: id
      }
    )

    update(stripe_customer_id: customer.id)
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to create Stripe customer: #{e.message}"
  end

  def update_stripe_customer
    return unless stripe_customer_id.present?

    Stripe::Customer.update(
      stripe_customer_id,
      email: email
    )
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to update Stripe customer: #{e.message}"
  end

  def create_subscription(price_id)
    return unless stripe_customer_id.present?

    subscription = Stripe::Subscription.create(
      customer: stripe_customer_id,
      items: [{ price: price_id }],
      trial_period_days: nil, # No trial period for paid subscriptions
      metadata: {
        user_id: id
      }
    )

    update(
      stripe_subscription_id: subscription.id,
      subscription_status: subscription.status,
      subscription_plan: price_id,
      subscription_ends_at: Time.at(subscription.current_period_end)
    )

    subscription
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to create subscription: #{e.message}"
    nil
  end

  def cancel_subscription
    return unless stripe_subscription_id.present?

    subscription = Stripe::Subscription.update(
      stripe_subscription_id,
      { cancel_at_period_end: true }
    )

    update(
      subscription_status: subscription.status,
      subscription_ends_at: Time.at(subscription.current_period_end)
    )

    subscription
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to cancel subscription: #{e.message}"
    nil
  end

  def reactivate_subscription
    return unless stripe_subscription_id.present?

    subscription = Stripe::Subscription.update(
      stripe_subscription_id,
      { cancel_at_period_end: false }
    )

    update(
      subscription_status: subscription.status,
      subscription_ends_at: Time.at(subscription.current_period_end)
    )

    subscription
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to reactivate subscription: #{e.message}"
    nil
  end

  def update_subscription_status
    return unless stripe_subscription_id.present?

    subscription = Stripe::Subscription.retrieve(stripe_subscription_id)
    
    update(
      subscription_status: subscription.status,
      subscription_ends_at: Time.at(subscription.current_period_end)
    )

    subscription
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to update subscription status: #{e.message}"
    nil
  end

  def trial?
    subscription_status == 'trial'
  end

  def active_subscription?
    subscription_status == 'active'
  end

  def subscription_active?
    # Temporarily frozen - all users have access without restrictions
    true
  end

  def trial_days_remaining
    # Temporarily frozen - always show unlimited trial days
    return 999 unless trial? && trial_ends_at.present?
    ((trial_ends_at - Time.current) / 1.day).ceil
  end

  def trial_percentage_completed
    return 0 unless trial? && trial_ends_at.present?
    total_days = ((trial_ends_at - created_at) / 1.day).ceil
    days_used = total_days - trial_days_remaining
    ((days_used.to_f / total_days) * 100).round
  end

  def subscription_days_remaining
    # Temporarily frozen - always show unlimited subscription days
    return 999 unless active_subscription? && subscription_ends_at.present?
    ((subscription_ends_at - Time.current) / 1.day).ceil
  end

  def subscription_expired?
    # Temporarily frozen - no subscriptions are considered expired
    false
  end
end 