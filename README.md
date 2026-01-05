# Solidgate Ruby SDK

A Ruby SDK for integrating with the Solidgate payment gateway API.

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

Configure the SDK with your Solidgate credentials:

```ruby
Solidgate.configure do |config|
  config.public_key = "your_public_key"
  config.private_key = "your_private_key"
  config.sandbox = true # Set to false for production
end
```

## Usage

### Creating a Payment

```ruby
# Create a payment
payment = Solidgate::Payment.new

response = payment.create(
  order_id: "order_123",
  amount: 1000, # Amount in cents ($10.00)
  currency: "USD",
  card_data: {
    number: "4111111111111111",
    exp_month: "12",
    exp_year: "2025",
    cvv: "123"
  },
  customer: {
    email: "customer@example.com",
    first_name: "John",
    last_name: "Doe"
  },
  description: "Test payment"
)
```

### Retrieving Payment Information

```ruby
payment = Solidgate::Payment.new
response = payment.get("payment_id_123")
```

### Capturing a Payment

```ruby
payment = Solidgate::Payment.new

# Capture full amount
payment.capture("payment_id_123")

# Capture partial amount
payment.capture("payment_id_123", amount: 500)
```

### Voiding a Payment

```ruby
payment = Solidgate::Payment.new
payment.void("payment_id_123")
```

### Refunding a Payment

```ruby
payment = Solidgate::Payment.new

# Full refund
payment.refund("payment_id_123")

# Partial refund with reason
payment.refund("payment_id_123", amount: 500, reason: "Customer request")
```

### Using a Custom Client

You can also create a client instance with custom configuration:

```ruby
client = Solidgate.client(
  public_key: "custom_public_key",
  private_key: "custom_private_key",
  sandbox: false
)

payment = Solidgate::Payment.new(client)
```

## Error Handling

The SDK provides specific error classes for different types of errors:

```ruby
begin
  payment.create(invalid_params)
rescue Solidgate::ValidationError => e
  puts "Validation errors: #{e.errors}"
rescue Solidgate::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue Solidgate::APIError => e
  puts "API error: #{e.message} (Code: #{e.code})"
rescue Solidgate::ConnectionError => e
  puts "Connection error: #{e.message}"
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

Bug reports and pull requests are welcome on GitHub at https://github.com/cgtrader/solidgate-ruby-sdk.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
