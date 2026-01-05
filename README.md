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

### Creating a Payment

```ruby
client = Solidgate::Client.new

payment_intent = {
  order_id:            'order_id_123', # Unique order identifier provided by the merchant
  product_id:          'product_id_456', # Product identifier generated in Solidgate Dashboard
  customer_account_id: 'customer_789', # Unique customer identifier provided by the merchant
  order_description:   'Premium package',
  type:                'auth',
  settle_interval:     0, # delay in hours for automatic settlement, 0 means immediate settlement
  retry_attempt:       3,
  language:            I18n.locale # language to render the payment form
}.to_json

encrypted_payment_intent = client.generate_intent(payment_intent)

# use the payment_data in your FE to render the payment form

payment_data = {
  merchant:      Solidgate.configuration.public_key,
  signature:     SolidgateClient.generate_signature(encrypted_payment_intent),
  paymentIntent: encrypted_payment_intent
}
```

### Handling Webhooks

```ruby
  payload = request.body.read
  Solidgate::Webhook.new.validate_signature(payload, request.headers['Signature']) # returns true/false to verify the webhook
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

Bug reports and pull requests are welcome on GitHub at https://github.com/cgtrader/solidgate-ruby-sdk.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
