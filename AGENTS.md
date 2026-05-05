# Solidgate Ruby SDK - Agent Documentation
# This file provides context for AI coding assistants about the codebase structure and conventions

## Overview
Solidgate Ruby SDK is an unofficial Ruby library for integrating with the Solidgate payment gateway API.
It provides a clean, object-oriented interface for payment processing, subscription management, and webhook handling.

## Integration Documentation
- Payment integration guide for humans and LLM agents: `docs/payment-integration-guide.md`

## Project Structure

### Core Components

#### `lib/solidgate-ruby-sdk.rb`
- Main entry point for the SDK
- Defines the `Solidgate` module with global configuration
- Provides `Solidgate.configure` and `Solidgate.configuration` methods
- Loads all core components

#### `lib/solidgate/configuration.rb`
- `Solidgate::Configuration` class for managing API credentials and settings
- Key attributes:
  - `public_key` / `private_key` - API authentication credentials
  - `sandbox` - Boolean for environment switching
  - `api_url` - Custom API endpoint (defaults to sandbox/production based on sandbox setting)
  - `timeout` / `open_timeout` - HTTP connection settings
  - `user_agent` - Custom user agent string
  - `webhook_public_key` / `webhook_private_key` - Webhook authentication
- Production URL: `https://subscriptions.solidgate.com`
- Sandbox URL: `https://subscriptions.solidgate.com`

#### `lib/solidgate/client.rb`
- `Solidgate::Client` class - Low-level HTTP client for API interactions
- Handles authentication via HMAC-SHA512 signatures
- Provides methods for all Solidgate API endpoints:
  - Payment operations: `create_payment`, `get_payment`, `capture_payment`, `void_payment`, `refund_payment`, `settle_payment`
  - Subscription operations: `create_subscription`, `subscription_status`, `switch_subscription_product`, `update_subscription_pause`, `create_subscription_pause`, `delete_subscription_pause`, `cancel_subscription`, `restore_subscription`, `update_subscription_payment_method`
  - Product operations: `create_product`, `update_product`, `create_price`, `products`, `product_prices`, `update_product_price`
  - Utility methods: `generate_intent`, `generate_signature`, `refund`, `alt_refund`, `order_status`, `apm_order_status`, `make_card_recurring`, `make_apm_recurring`
- Private methods for HTTP operations: `get`, `post`, `patch`, `delete`, `request`
- Encryption: `encrypt_payload` for payment intent generation (AES-256-CBC)

#### `lib/solidgate/payment.rb`
- `Solidgate::Payment` class - High-level payment resource wrapper
- Provides a more Ruby-idiomatic interface around `Solidgate::Client`
- Includes validation for payment parameters
- Methods: `create`, `get`, `capture`, `void`, `refund`

#### `lib/solidgate/webhook.rb`
- `Solidgate::Webhook` class - Webhook signature validation
- Validates incoming webhook requests using configured webhook keys
- Method: `validate_signature(payload, signature)`

#### `lib/solidgate/errors.rb`
- Custom error hierarchy:
  - `Solidgate::Error` - Base error class
  - `Solidgate::ConfigurationError` - Missing/invalid configuration
  - `Solidgate::APIError` - General API errors (includes http_status)
  - `Solidgate::AuthenticationError` - 401 responses
  - `Solidgate::InvalidRequestError` - 400 responses
  - `Solidgate::ConnectionError` - Network failures
  - `Solidgate::TimeoutError` - Request timeouts
  - `Solidgate::RateLimitError` - 429 responses
  - `Solidgate::ValidationError` - Parameter validation (includes errors hash)

#### `lib/solidgate/version.rb`
- Version constant: `Solidgate::VERSION = "0.2.0"`

### Test Structure

#### `spec/spec_helper.rb`
- RSpec configuration with WebMock and VCR
- Disables real HTTP connections
- Filters sensitive data (keys, signatures) from test recordings
- Provides `:configured` metadata for tests requiring configuration

#### `spec/solidgate/`
- `client_spec.rb` - Client HTTP method tests
- `configuration_spec.rb` - Configuration validation tests
- `payment_spec.rb` - Payment resource tests

### Utilities

#### `bin/console`
- Interactive Ruby console with SDK preloaded
- Uses environment variables for credentials if available

#### `bin/setup`
- Automated setup script (runs bundle install)

#### `Rakefile`
- Default task runs specs
- Uses bundler/gem_tasks for gem-related tasks

#### `examples/basic_usage.rb`
- Example demonstrating common SDK usage patterns
- Shows error handling for different error types

## Key Conventions

### Authentication
- All API requests require HMAC-SHA512 signature
- Signature format: `Base64(HMAC_SHA516(private_key, public_key + json + public_key))`
- Headers: `Merchant` (public key) and `Signature`

### Error Handling
- Use specific error classes for different failure scenarios
- API errors include `code`, `details`, and `http_status`
- Validation errors include detailed `errors` hash

### API URL Selection
- Uses `sandbox?` flag to choose between sandbox/production
- Can override with custom `api_url` for testing

### Payment Amounts
- All amounts in minor units (cents for USD)
- Currency codes are 3-letter ISO 4217

### Webhook Security
- Validate signatures using `webhook_public_key` and `webhook_private_key`
- Never trust webhook data without validation

## Development Notes

### Adding New API Endpoints
1. Add method to `Solidgate::Client` with proper documentation
2. Follow existing naming conventions (snake_case for Ruby, kebab-case for API paths)
3. Add corresponding tests in `spec/solidgate/client_spec.rb`
4. Update README.md with usage examples

### Code Style
- Frozen string literals: `# frozen_string_literal: true`
- 2-space indentation
- YARD documentation for public methods
- Follow Ruby conventions (snake_case for methods/variables)

### Versioning
- Follows Semantic Versioning (semver.org)
- Version defined in `lib/solidgate/version.rb`
- Update CHANGELOG.md for each release

## Environment Variables
- `SOLIDGATE_PUBLIC_KEY` - Public API key
- `SOLIDGATE_PRIVATE_KEY` - Private API key
- `SOLIDGATE_WEBHOOK_PUBLIC_KEY` - Webhook public key
- `SOLIDGATE_WEBHOOK_PRIVATE_KEY` - Webhook private key

## Dependencies
- Runtime: `faraday`, `faraday-multipart`
- Development: `rspec`, `webmock`, `vcr`, `rubocop`, `pry`
