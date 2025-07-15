# Cotalo Subscription Setup Guide

## Overview
This guide explains how to set up the subscription functionality for Cotalo using Stripe.

## Required Environment Variables

Add the following environment variables to your `.env` file:

```bash
# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=pk_live_51RiJHVByovk24eSGDDFt6bWsGRwFMe0M3TX4J3xB0f2eIeq6enRGKr7jyPOoNTV257aoni3jtUrfLP5yfXrA4bXZ00MLxUdH4I
STRIPE_SECRET_KEY=sk_test_your_stripe_test_key_here
STRIPE_WEBHOOK_SECRET=whsec_gtf6Z8rgt17AZfI13qneKAgaedn9o6oN

# Stripe Price ID for the subscription
STRIPE_PRICE_ID=price_...
```

## Stripe Setup Steps

### 1. Create a Stripe Account
1. Go to [stripe.com](https://stripe.com) and create an account
2. Complete the account verification process

### 2. Get API Keys
1. In your Stripe Dashboard, go to **Developers > API keys**
2. Copy your **Publishable key** and **Secret key**
3. Add them to your environment variables

### 3. Create a Product and Price
1. In your Stripe Dashboard, go to **Products**
2. Click **Add product**
3. Set the following:
   - **Name**: Cotalo Annual Subscription
   - **Description**: Annual subscription to Cotalo manufacturing cost calculator
   - **Pricing**: $3,000 MXN per year
   - **Billing**: Recurring, yearly
4. Copy the **Price ID** (starts with `price_`) and add it to `STRIPE_PRICE_ID`

### 4. Set Up Webhooks
1. In your Stripe Dashboard, go to **Developers > Webhooks**
2. Click **Add endpoint**
3. Set the endpoint URL to: `https://yourdomain.com/stripe/webhook`
4. Select the following events:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
5. Copy the **Webhook signing secret** and add it to `STRIPE_WEBHOOK_SECRET`

### 5. Configure Customer Portal (Optional)
1. In your Stripe Dashboard, go to **Settings > Customer Portal**
2. Enable the customer portal
3. Configure the settings as needed for subscription management

## Testing the Subscription System

### 1. Test Cards
Use these test card numbers for testing:
- **Success**: `4242 4242 4242 4242`
- **Decline**: `4000 0000 0000 0002`
- **Requires Authentication**: `4000 0025 0000 3155`

### 2. Test Flow
1. Create a new user account
2. Navigate to `/subscribe`
3. Click "Suscribirse Ahora"
4. Complete the payment with a test card
5. Verify the subscription is created in Stripe
6. Check that the user's subscription status is updated

## Subscription Features

### Trial Period
- New users get a 14-day trial period
- Trial users can access all features
- Trial status is displayed in the navbar
- Users are prompted to subscribe when trial is about to expire

### Subscription Management
- Users can view their subscription details at `/subscription`
- Users can update payment methods via Stripe Customer Portal
- Users can cancel their subscription (cancels at period end)
- Users can reactivate canceled subscriptions

### Email Notifications
The system sends emails for:
- Subscription welcome
- Payment failures
- Subscription cancellations
- Subscription expirations
- Payment successes

## Troubleshooting

### Common Issues

1. **Webhook not receiving events**
   - Check that the webhook URL is correct
   - Verify the webhook secret is set correctly
   - Check your server logs for webhook errors

2. **Subscription not creating**
   - Verify the Stripe price ID is correct
   - Check that the user has a Stripe customer ID
   - Review Stripe dashboard for any errors

3. **Payment failing**
   - Use test cards for testing
   - Check Stripe dashboard for payment failure reasons
   - Verify webhook events are being processed

### Debugging
- Check Rails logs for Stripe-related errors
- Monitor Stripe dashboard for webhook delivery status
- Use Stripe CLI for local webhook testing

## Security Considerations

1. **Never commit API keys to version control**
2. **Use environment variables for all sensitive data**
3. **Verify webhook signatures to prevent replay attacks**
4. **Use HTTPS in production**
5. **Regularly rotate API keys**

## Production Deployment

1. Switch to live Stripe keys
2. Update webhook endpoint URL to production domain
3. Test the complete subscription flow
4. Monitor webhook delivery and error rates
5. Set up proper logging and monitoring 