# Solidgate Ruby SDK

A Ruby (unofficial) SDK for integrating with the Solidgate payment gateway API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'solidgate'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install solidgate

## Configuration

Configure the SDK with your Solidgate credentials in an initializer file:

```ruby
Solidgate.configure do |config|
  config.public_key = 'your_public_key'
  config.private_key = 'your_private_key'
  config.webhook_public_key = 'your_webhook_public_key'
  config.webhook_private_key = 'your_webhook_private_key'
  config.sandbox = true
end
```

## Usage

### Creating a Client

```ruby
# Using global configuration
client = Solidgate::Client.new

# Using custom configuration
client = Solidgate::Client.new(
  public_key: 'your_public_key',
  private_key: 'your_private_key'
)
```

### Payment Intent (Frontend Integration)

Generate an encrypted payment intent for use with Solidgate's JavaScript SDK:

```ruby
SolidgateClient = Solidgate::Client.new

payment_intent = {
  order_id:            'order_id_123',       # Unique order identifier provided by the merchant
  product_id:          'product_id_456',     # Product identifier generated in Solidgate Dashboard
  customer_account_id: 'customer_789',       # Unique customer identifier provided by the merchant
  order_description:   'Premium package',
  type:                'auth',               # 'auth' for authorization only, 'sale' for immediate charge
  settle_interval:     0,                    # Delay in hours for automatic settlement, 0 means immediate
  retry_attempt:       3,
  language:            I18n.locale           # Language to render the payment form
}.to_json

encrypted_payment_intent = client.generate_intent(payment_intent)

# use the payment_data in your FE to render the payment form

payment_data = {
  merchant:      Solidgate.configuration.public_key,
  signature:     SolidgateClient.generate_signature(encrypted_payment_intent),
  paymentIntent: encrypted_payment_intent
}
```

### Payment Operations

```ruby
client = Solidgate::Client.new

# Create a new payment
response = client.create_payment(
  amount: 1000,              # Amount in minor units (e.g., cents)
  currency: 'USD',
  order_id: 'order_123',
  customer_email: 'customer@example.com'
)

# Get payment details
payment = client.get_payment('payment_id_123')

# Capture an authorized payment
client.capture_payment('payment_id_123')

# Capture with partial amount
client.capture_payment('payment_id_123', amount: 500)

# Void an authorized payment (before settlement)
client.void_payment('payment_id_123')

# Refund a captured payment
client.refund_payment('payment_id_123')

# Partial refund
client.refund_payment('payment_id_123', amount: 500, reason: 'Customer request')
```

### Subscription Management

```ruby
client = Solidgate::Client.new

# Create a subscription
subscription = client.create_subscription(
  product_id: 'prod_123',
  customer_account_id: 'customer_456',
  order_id: 'order_789'
)

# Get subscription status
status = client.subscription_status('subscription_id_123')

# Switch to a different product/plan
client.switch_subscription_product(
  subscription_id: 'sub_123',
  new_product_id: 'prod_premium_456'
)

# Cancel a subscription
client.cancel_subscription(
  subscription_id: 'sub_123',
  cancel_at_period_end: true,
  reason: 'Customer requested cancellation'
)
```

### Subscription Pause Scheduling

```ruby
client = Solidgate::Client.new

# Create a pause schedule
client.create_subscription_pause('subscription_id_123',
  pause_at: '2026-02-01T00:00:00Z',
  resume_at: '2026-03-01T00:00:00Z'
)

# Update an existing pause schedule
client.update_subscription_pause('subscription_id_123',
  resume_at: '2026-04-01T00:00:00Z'
)

# Delete/cancel a pending pause schedule
client.delete_subscription_pause('subscription_id_123')
```

### Product & Price Management

```ruby
client = Solidgate::Client.new

# Create a product
product = client.create_product(
  name: 'Premium Plan',
  description: 'Access to all premium features',
  type: 'subscription'
)

# Create a price for a product
price = client.create_price('product_id_123',
  amount: 1999,           # $19.99 in cents
  currency: 'USD',
  interval: 'month'       # Billing interval for subscriptions
)

# List all products
all_products = client.products

# Get prices for a specific product
prices = client.product_prices('product_id_123')
```

### Signature Generation

Generate signatures for API authentication or custom integrations:

```ruby
client = Solidgate::Client.new

# Generate signature with configured keys
signature = client.generate_signature(json_payload)

# Generate signature with custom keys
signature = client.generate_signature(
  json_payload,
  public_key: 'custom_public_key',
  private_key: 'custom_private_key'
)
```

### Handling Webhooks

```ruby
# In your webhook controller
payload = request.body.read
signature = request.headers['Signature']

webhook = Solidgate::Webhook.new
if webhook.validate_signature(payload, signature)
  # Process the webhook event
  event = JSON.parse(payload)
  # Handle event...
else
  # Invalid signature, reject the webhook
  head :unauthorized
end
```

## Available Error Classes

- `Solidgate::Error` - Base error class
- `Solidgate::ConfigurationError` - Configuration issues
- `Solidgate::ValidationError` - Parameter validation errors
- `Solidgate::AuthenticationError` - Authentication failures
- `Solidgate::InvalidRequestError` - Invalid request parameters
- `Solidgate::APIError` - General API errors
- `Solidgate::ConnectionError` - Network connectivity issues
- `Solidgate::TimeoutError` - Request timeout
- `Solidgate::RateLimitError` - Rate limit exceeded

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/carrfane/solidgate-ruby-sdk.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
