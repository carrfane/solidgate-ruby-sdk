# frozen_string_literal: true

require "faraday"
require "faraday/multipart"
require "json"
require "digest"
require "base64"
require "openssl"
require 'pry'

module Solidgate
  # HTTP client for interacting with the Solidgate API.
  # Provides methods for payment processing, subscription management,
  # product management, and payment intent generation.
  #
  # @example Basic usage
  #   client = Solidgate::Client.new
  #   client.create_payment(amount: 1000, currency: 'USD')
  #
  # @example With custom configuration
  #   client = Solidgate::Client.new(public_key: 'pk_xxx', private_key: 'sk_xxx')
  #
  class Client
    attr_reader :config

    # Length of initialization vector for AES encryption (in bytes)
    IV_LENGTH = 16

    # Length of encryption key for AES-256 encryption (in bytes)
    KEY_LENGTH = 32

    # Initializes a new Solidgate API client.
    #
    # @param options [Configuration, Hash] configuration options or a Configuration object.
    #   When a Hash is provided, it will be converted to a Configuration object.
    #   Defaults to global Solidgate.configuration.
    # @raise [ConfigurationError] if required configuration is missing or invalid
    #
    # @example Using global configuration
    #   client = Solidgate::Client.new
    #
    # @example Using custom options
    #   client = Solidgate::Client.new(public_key: 'pk_xxx', private_key: 'sk_xxx')
    #
    def initialize(options = Solidgate.configuration)
      @config = build_config(options)
      @config.validate!
    end

    # Creates a new payment charge.
    #
    # @param params [Hash] payment parameters including:
    #   - :amount [Integer] payment amount in minor units (e.g., cents)
    #   - :currency [String] three-letter ISO currency code (e.g., 'USD')
    #   - :order_id [String] unique order identifier
    #   - :customer_email [String] customer's email address
    #   - :card_number [String] credit card number (if applicable)
    # @return [Hash] payment response containing payment ID, status, and transaction details
    # @raise [InvalidRequestError] if payment parameters are invalid
    # @raise [AuthenticationError] if API credentials are invalid
    #
    def create_payment(params)
      post("/v1/charge", body: params)
    end

    # Retrieves payment details and current status.
    #
    # @param payment_id [String] the unique payment identifier returned from create_payment
    # @return [Hash] payment details including:
    #   - :id [String] payment identifier
    #   - :status [String] current payment status
    #   - :amount [Integer] payment amount
    #   - :currency [String] payment currency
    #   - :created_at [String] timestamp of payment creation
    # @raise [InvalidRequestError] if payment_id is not found
    #
    def get_payment(payment_id)
      get("/v1/charge/#{payment_id}")
    end

    # Captures a previously authorized payment.
    # Use this to finalize a payment that was created with type 'auth'.
    #
    # @param payment_id [String] the unique payment identifier of an authorized payment
    # @param params [Hash] optional capture parameters:
    #   - :amount [Integer] amount to capture (for partial captures), defaults to full amount
    # @return [Hash] capture response with updated payment status
    # @raise [InvalidRequestError] if payment cannot be captured (wrong status, already captured, etc.)
    #
    def capture_payment(payment_id, params = {})
      post("/v1/charge/#{payment_id}/capture", body: params)
    end

    # Voids a payment that has not yet been settled.
    # Voiding cancels the authorization and releases the hold on customer funds.
    #
    # @param payment_id [String] the unique payment identifier of an authorized (unsettled) payment
    # @return [Hash] void response with updated payment status
    # @raise [InvalidRequestError] if payment cannot be voided (already settled, already voided, etc.)
    #
    def void_payment(payment_id)
      post("/v1/charge/#{payment_id}/void")
    end

    # Refunds a captured/settled payment.
    # Supports both full and partial refunds.
    #
    # @param payment_id [String] the unique payment identifier of a captured payment
    # @param params [Hash] optional refund parameters:
    #   - :amount [Integer] refund amount in minor units (for partial refunds)
    #   - :reason [String] reason for the refund
    # @return [Hash] refund response including refund ID and status
    # @raise [InvalidRequestError] if payment cannot be refunded
    #
    def refund_payment(payment_id, params = {})
      post("/v1/charge/#{payment_id}/refund", body: params)
    end

    # Settles a payment for final processing.
    # Note: This method currently has a bug and returns config.api_url instead of making an API call.
    #
    # @param params [Hash] settlement parameters
    # @return [String] currently returns the API URL (likely unintended behavior)
    # @todo Fix this method to properly call the settlement endpoint
    #
    def settle_payment(params = {})
      config.api_url
    end

    # Creates a new recurring subscription.
    #
    # @param params [Hash] subscription parameters including:
    #   - :product_id [String] Solidgate product identifier
    #   - :customer_account_id [String] unique customer identifier
    #   - :order_id [String] unique order identifier
    #   - :payment_method [Hash] payment method details
    # @return [Hash] subscription response including subscription ID and status
    # @raise [InvalidRequestError] if subscription parameters are invalid
    #
    def create_subscription(params)
      post("/v1/subscription", body: params)
    end

    # Retrieves the current status and details of a subscription.
    #
    # @param subscription_id [String] the unique subscription identifier
    # @return [Hash] subscription details including:
    #   - :id [String] subscription identifier
    #   - :status [String] current subscription status (active, paused, cancelled, etc.)
    #   - :current_period_start [String] start of current billing period
    #   - :current_period_end [String] end of current billing period
    # @raise [InvalidRequestError] if subscription_id is not found
    #
    def subscription_status(subscription_id)
      post("/api/v1/subscription/status", body: { subscription_id: subscription_id })
    end

    # Switches a subscription to a different product/plan.
    # Use this for upgrades, downgrades, or plan changes.
    #
    # @param params [Hash] subscription update parameters:
    #   - :subscription_id [String] the subscription to update
    #   - :new_product_id [String] Solidgate product ID to switch to
    # @return [Hash] update response with new subscription details
    # @raise [InvalidRequestError] if subscription or product is invalid
    #
    # @example Upgrade a subscription
    #   client.switch_subscription_product(
    #     subscription_id: 'sub_12345',
    #     new_product_id: 'prod_premium_67890'
    #   )
    #
    def switch_subscription_product(params)
      post("/api/v1/subscription/switch-subscription-product", body: params)
    end

    # Updates an existing pause schedule for a subscription.
    #
    # @param subscription_id [String] the unique subscription identifier
    # @param params [Hash] pause schedule update parameters:
    #   - :pause_at [String] new date/time to pause the subscription
    #   - :resume_at [String] new date/time to resume the subscription
    # @return [Hash] updated pause schedule details
    # @raise [InvalidRequestError] if subscription has no pause schedule or params are invalid
    #
    def update_subscription_pause(subscription_id, params)
      patch("/api/v1/subscriptions/#{subscription_id}/pause-schedule", body: params)
    end

    # Creates a pause schedule for a subscription.
    # The subscription will be paused and resumed at the specified times.
    #
    # @param subscription_id [String] the unique subscription identifier
    # @param params [Hash] pause schedule parameters:
    #   - :pause_at [String] date/time to pause the subscription
    #   - :resume_at [String] date/time to resume the subscription
    # @return [Hash] created pause schedule details
    # @raise [InvalidRequestError] if subscription is invalid or already has a pause schedule
    #
    def create_subscription_pause(subscription_id, params)
      post("/api/v1/subscriptions/#{subscription_id}/pause-schedule", body: params)
    end

    # Deletes/cancels a pending pause schedule for a subscription.
    #
    # @param subscription_id [String] the unique subscription identifier
    # @return [Hash] confirmation of pause schedule deletion
    # @raise [InvalidRequestError] if subscription has no pause schedule
    #
    def delete_subscription_pause(subscription_id)
      delete("/api/v1/subscriptions/#{subscription_id}/pause-schedule")
    end

    # Cancels an active subscription.
    #
    # @param params [Hash] cancellation parameters:
    #   - :subscription_id [String] the subscription to cancel
    #   - :cancel_at_period_end [Boolean] if true, cancel at end of current period
    #   - :reason [String] optional cancellation reason
    # @return [Hash] cancelled subscription details
    # @raise [InvalidRequestError] if subscription is invalid or already cancelled
    #
    def cancel_subscription(params)
      post("/api/v1/subscription/cancel", body: params)
    end

    # Creates a new product in the Solidgate catalog.
    #
    # @param params [Hash] product parameters:
    #   - :name [String] product name
    #   - :description [String] product description
    #   - :type [String] product type (e.g., 'subscription', 'one_time')
    # @return [Hash] created product details including product_id
    # @raise [InvalidRequestError] if product parameters are invalid
    #
    def create_product(params)
      post("/api/v1/products", body: params)
    end

    # Creates a new price for an existing product.
    #
    # @param product_id [String] the product to add pricing to
    # @param params [Hash] price parameters:
    #   - :amount [Integer] price amount in minor units
    #   - :currency [String] three-letter ISO currency code
    #   - :interval [String] billing interval for subscriptions (e.g., 'month', 'year')
    # @return [Hash] created price details including price_id
    # @raise [InvalidRequestError] if product_id is invalid or price params are invalid
    #
    def create_price(product_id, params)
      post("/api/v1/products/#{product_id}/prices", body: params)
    end

    # Retrieves all products from the Solidgate catalog.
    #
    # @return [Hash] list of all products with their details
    #
    def products
      get("/api/v1/products")
    end

    # Retrieves all prices for a specific product.
    #
    # @param product_id [String] the product to retrieve prices for
    # @return [Hash] list of prices associated with the product
    # @raise [InvalidRequestError] if product_id is not found
    #
    def product_prices(product_id)
      get("/api/v1/products/#{product_id}/prices")
    end

    # Generates an encrypted payment intent for client-side payment form rendering.
    # The encrypted intent is used with Solidgate's JavaScript SDK to securely
    # initialize payment forms without exposing sensitive data.
    #
    # @param params [String] JSON string containing payment intent parameters:
    #   - order_id: unique order identifier
    #   - product_id: Solidgate product identifier
    #   - customer_account_id: unique customer identifier
    #   - order_description: description of the order
    #   - type: payment type ('auth' or 'sale')
    # @return [String] Base64-encoded encrypted payment intent
    #
    # @example Generate payment intent for frontend
    #   intent_params = { order_id: 'ord_123', product_id: 'prod_456' }.to_json
    #   encrypted_intent = client.generate_intent(intent_params)
    #
    def generate_intent(params)
      encrypt_payload(params)
    end

    # Updates an existing price for a product.
    # Use this to modify the amount, currency, or billing interval of a price.
    #
    # @param product_id [String] the product identifier that owns the price
    # @param price_id [String] the price identifier to update
    # @param params [Hash] price update parameters:
    # @return [Hash] updated price details including price_id
    # @raise [InvalidRequestError] if product_id, price_id, or params are invalid
    #
    # @example Update a price amount
    #   client.update_product_price('prod_123', 'price_456', amount: 2000)
    #
    def update_product_price(product_id, price_id, params)
      patch("/api/v1/products/#{product_id}/prices/#{price_id}", body: params)
    end

    # Generates an HMAC-SHA512 signature for API request authentication.
    # The signature is required for all API requests and webhook validation.
    #
    # @param json_string [String] the JSON payload to sign
    # @param public_key [String] merchant public key (defaults to configured public_key)
    # @param private_key [String] merchant private key (defaults to configured private_key)
    # @return [String] Base64-encoded HMAC-SHA512 signature
    #
    # @example Generate signature for a payment intent
    #   signature = client.generate_signature(encrypted_intent)
    #
    def generate_signature(json_string, public_key: config.public_key, private_key: config.private_key)
      digest = OpenSSL::Digest.new('sha512')
      instance = OpenSSL::HMAC.new(private_key, digest)
      instance.update(public_key + json_string + public_key)
      Base64.strict_encode64(instance.hexdigest)
    end

    # Restores a previously cancelled subscription.
    # Use this to reactivate a subscription that was cancelled but is still within
    # the restoration period.
    #
    # @param params [Hash] restoration parameters:
    #   - :subscription_id [String] the subscription identifier to restore
    # @return [Hash] restored subscription details including:
    #   - :id [String] subscription identifier
    #   - :status [String] new subscription status (typically 'active')
    # @raise [InvalidRequestError] if subscription cannot be restored (expired, already active, etc.)
    #
    # @example Restore a cancelled subscription
    #   client.restore_subscription(subscription_id: 'sub_12345')
    #
    def restore_subscription(params)
      post("/api/v1/subscription/restore", body: params)
    end

    # Creates a refund for a transaction.
    #
    # @param params [Hash] refund parameters:
    #   - :order_id [String] the order identifier to refund
    #   - :amount [Integer] refund amount in minor units (for partial refunds)
    # @return [Hash] refund response including refund status and details
    # @raise [InvalidRequestError] if refund parameters are invalid
    #
    # @example Create a refund
    #   client.refund(order_id: 'ord_12345', amount: 1000)
    #
    def refund(params)
      post("/api/v1/refund", body: params, base_url: "https://pay.solidgate.com")
    end

    # Updates the payment method (token) associated with an existing subscription.
    #
    # @param params [Hash] update parameters including:
    #   - :subscription_id [String] the subscription to update
    #   - :token [String] new payment token / payment method identifier
    # @return [Hash] response from the API with updated subscription/payment method details
    # @raise [InvalidRequestError] if params are invalid
    #
    # @example Update a subscription's payment method
    #   client.update_subscription_payment_method(
    #     subscription_id: 'sub_123',
    #     token: 'tok_abc123'
    #   )
    def update_subscription_payment_method(params)
      post("/api/v1/subscription/update-token", body: params)
    end

    # Retrieves order status from Solidgate pay domain.
    #
    # @param params [Hash] status request parameters:
    #   - :order_id [String] unique order identifier
    #   - :payment_id [String] optional payment identifier
    # @return [Hash] order status response
    # @raise [InvalidRequestError] if params are invalid
    #
    # @example Get order status
    #   client.order_status(order_id: 'order_123')
    def order_status(params)
      post('/api/v1/status', body: params, base_url: "https://pay.solidgate.com")
    end

    def make_card_recurring(params)
      post('/api/v1/recurring', body: params, base_url: "https://pay.solidgate.com")
    end

    private

    # Builds a Configuration object from the provided options.
    #
    # @param options [Configuration, Hash] configuration options
    # @return [Configuration] the configuration object
    #
    def build_config(options)
      if options.is_a?(Configuration)
        options
      else
        config = Configuration.new
        options.each { |key, value| config.send("#{key}=", value) if config.respond_to?("#{key}=") }
        config
      end
    end

    # Creates and caches a Faraday HTTP connection.
    #
    # @return [Faraday::Connection] configured HTTP connection
    #
    def connection
      @connection ||= connection_for(config.api_url)
    end

    # Creates a Faraday HTTP connection for the specified base URL.
    #
    # @param base_url [String] the base URL for the connection
    # @return [Faraday::Connection] configured HTTP connection
    #
    def connection_for(base_url)
      Faraday.new(
        url: base_url,
        headers: default_headers
      ) do |conn|
        conn.request :multipart
        conn.request :url_encoded
        conn.response :json, content_type: /\bjson$/
        conn.adapter Faraday.default_adapter

        conn.options.timeout = config.timeout
        conn.options.open_timeout = config.open_timeout
      end
    end

    # Returns default HTTP headers for API requests.
    #
    # @return [Hash] default headers including Accept, Content-Type, and User-Agent
    #
    def default_headers
      {
        "Accept" => "application/json",
        "Content-Type" => "application/json",
        "User-Agent" => config.user_agent
      }
    end

    # Performs a GET request to the specified path.
    #
    # @param path [String] API endpoint path
    # @return [Hash] parsed response body
    #
    def get(path)
      request(:get, path)
    end

    # Performs a POST request to the specified path.
    #
    # @param path [String] API endpoint path
    # @param body [Hash] request body parameters
    # @param base_url [String, nil] optional base URL to override the default API URL
    # @return [Hash] parsed response body
    #
    def post(path, body: {}, base_url: nil)
      request(:post, path, body: body, base_url: base_url)
    end

    # Performs a PATCH request to the specified path.
    #
    # @param path [String] API endpoint path
    # @param body [Hash] request body parameters
    # @return [Hash] parsed response body
    #
    def patch(path, body: {})
      request(:patch, path, body: body)
    end

    # Performs a DELETE request to the specified path.
    #
    # @param path [String] API endpoint path
    # @return [Hash] parsed response body
    #
    def delete(path)
      request(:delete, path)
    end

    # Performs an HTTP request with authentication and signature.
    #
    # @param method [Symbol] HTTP method (:get, :post, :patch, :delete)
    # @param path [String] API endpoint path
    # @param body [Hash, nil] optional request body
    # @param base_url [String, nil] optional base URL to override the default API URL
    # @return [Hash] parsed response body
    # @raise [TimeoutError] if request times out
    # @raise [ConnectionError] if connection fails
    # @raise [Error] for other unexpected errors
    #
    def request(method, path, body: nil, base_url: nil)
      body_json = body ? JSON.generate(body) : ''
      signature = generate_signature(body_json)

      conn = base_url ? connection_for(base_url) : connection

      response = conn.send(method) do |req|
        req.url path
        req.headers["Merchant"] = config.public_key
        req.headers["Signature"] = signature
        req.body = body_json if body_json
      end

      handle_response(response)
    rescue Faraday::TimeoutError
      raise TimeoutError, "Request timed out"
    rescue Faraday::ConnectionFailed => e
      raise ConnectionError, "Connection failed: #{e.message}"
    rescue => e
      raise Error, "Unexpected error: #{e.message}"
    end

    # Handles HTTP response and raises appropriate errors for non-success statuses.
    #
    # @param response [Faraday::Response] the HTTP response object
    # @return [Hash] parsed response body for successful requests
    # @raise [InvalidRequestError] for 400 status
    # @raise [AuthenticationError] for 401 status
    # @raise [RateLimitError] for 429 status
    # @raise [APIError] for 5xx statuses and unknown errors
    #
    def handle_response(response)
      case response.status
      when 200..299
        response.body
      when 400
        raise InvalidRequestError.new(
          extract_error_message(response),
          extract_error_code(response),
          response.body,
          response.status
        )
      when 401
        raise AuthenticationError.new(
          "Authentication failed",
          "authentication_failed",
          response.body,
          response.status
        )
      when 429
        raise RateLimitError.new(
          "Rate limit exceeded",
          "rate_limit_exceeded",
          response.body,
          response.status
        )
      when 500..599
        raise APIError.new(
          "Server error",
          "server_error",
          response.body,
          response.status
        )
      else
        raise APIError.new(
          "Unknown error",
          "unknown_error",
          response.body,
          response.status
        )
      end
    end

    # Extracts error message from API error response.
    #
    # @param response [Faraday::Response] the HTTP response object
    # @return [String] error message or "Unknown error" if not found
    #
    def extract_error_message(response)
      return "Unknown error" unless response.body.is_a?(Hash)

      response.body["error"]["message"] || "API error"
    rescue
      "Unknown error"
    end

    # Extracts error code from API error response.
    #
    # @param response [Faraday::Response] the HTTP response object
    # @return [String, nil] error code or nil if not found
    #
    def extract_error_code(response)
      return nil unless response.body.is_a?(Hash)

      response.body["error"]["code"]
    rescue
      nil
    end

    # Encrypts payload using AES-256-CBC encryption for secure transmission.
    # Uses the first 32 characters of the private key as the encryption key.
    #
    # @param attributes [String] JSON string to encrypt
    # @return [String] URL-safe Base64-encoded encrypted payload (IV prepended)
    #
    def encrypt_payload(attributes)
      key = config.private_key[0, KEY_LENGTH]
      iv = OpenSSL::Random.random_bytes(IV_LENGTH)
      cipher = OpenSSL::Cipher.new('aes-256-cbc')
      cipher.encrypt
      cipher.key = key
      cipher.iv = iv
      encrypted = cipher.update(attributes) + cipher.final

      base64_encoded = Base64.urlsafe_encode64(iv + encrypted)
      base64_encoded.gsub('+', '-').gsub('/', '_')
    end
  end
end
