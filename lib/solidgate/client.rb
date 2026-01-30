# frozen_string_literal: true

require "faraday"
require "faraday/multipart"
require "json"
require "digest"
require "base64"
require "openssl"
require 'pry'

module Solidgate
  # HTTP client for interacting with the Solidgate API
  class Client
    attr_reader :config

    IV_LENGTH = 16
    KEY_LENGTH = 32

    def initialize(options = Solidgate.configuration)
      @config = build_config(options)
      @config.validate!
    end

    # Create a new payment
    #
    # @param params [Hash] payment parameters
    # @return [Hash] payment response
    def create_payment(params)
      post("/v1/charge", params)
    end

    # Get payment status
    #
    # @param payment_id [String] payment ID
    # @return [Hash] payment details
    def get_payment(payment_id)
      get("/v1/charge/#{payment_id}")
    end

    # Capture a payment
    #
    # @param payment_id [String] payment ID
    # @param params [Hash] capture parameters (optional)
    # @return [Hash] capture response
    def capture_payment(payment_id, params = {})
      post("/v1/charge/#{payment_id}/capture", params)
    end

    # Void a payment
    #
    # @param payment_id [String] payment ID
    # @return [Hash] void response
    def void_payment(payment_id)
      post("/v1/charge/#{payment_id}/void")
    end

    # Refund a payment
    #
    # @param payment_id [String] payment ID
    # @param params [Hash] refund parameters
    # @return [Hash] refund response
    def refund_payment(payment_id, params = {})
      post("/v1/charge/#{payment_id}/refund", params)
    end

    # Settle a payment
    #
    # @param params [Hash] settlement parameters
    # @return [Hash] settlement response
    def settle_payment(params = {})
      conifg.api_url
    end

    # Create a subscription
    #
    # @param params [Hash] subscription parameters
    # @return [Hash] subscription response
    def create_subscription(params)
      post("/v1/subscription", params)
    end

    # Get subscription details
    #
    # @param subscription_id [String] subscription ID
    # @return [Hash] subscription details
    def subscription_status(subscription_id)
      post("/api/v1/subscription/status", { subscription_id: subscription_id })
    end

    # Update subscription product
    #
    # @param params [Hash] subscription update parameters
    # @return [Hash] update response
    # params = { subscription_id: "sub_12345", new_product_id: "prod_67890" }
    # new product_id is the Solidgate ID of the product to switch to
    def switch_subscription_product(params)
      post("/api/v1/subscription/switch-subscription-product", params)
    end

    def update_subscription_pause(subscription_id, params)
      patch("/api/v1/subscriptions/#{subscription_id}/pause-schedule", params)
    end

    def create_subscription_pause(subscription_id, params)
      post("/api/v1/subscriptions/#{subscription_id}/pause-schedule", params)
    end

    def delete_subscription_pause(subscription_id)
      delete("/api/v1/subscriptions/#{subscription_id}/pause-schedule")
    end

    def create_product(params)
      post("/api/v1/products", params)
    end

    def create_price(product_id, params)
      post("/api/v1/products/#{product_id}/prices", params)
    end

    def products
      get("/api/v1/products")
    end

    def product_prices(product_id)
      get("/api/v1/products/#{product_id}/prices")
    end

    def generate_intent(params)
      encrypt_payload(params)
    end

    def generate_signature(json_string, public_key: config.public_key, private_key: config.private_key)
      digest = OpenSSL::Digest.new('sha512')
      instance = OpenSSL::HMAC.new(private_key, digest)
      instance.update(public_key + json_string + public_key)
      Base64.strict_encode64(instance.hexdigest)
    end

    private

    def build_config(options)
      if options.is_a?(Configuration)
        options
      else
        config = Configuration.new
        options.each { |key, value| config.send("#{key}=", value) if config.respond_to?("#{key}=") }
        config
      end
    end

    def connection
      @connection ||= Faraday.new(
        url: config.api_url,
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

    def default_headers
      {
        "Accept" => "application/json",
        "Content-Type" => "application/json",
        "User-Agent" => config.user_agent
      }
    end

    def get(path)
      request(:get, path)
    end

    def post(path, body = {})
      request(:post, path, body)
    end

    def patch(path, body = {})
      request(:patch, path, body)
    end

    def delete(path)
      request(:delete, path)
    end

    def request(method, path, body = nil)
      body_json = body ? JSON.generate(body) : ''
      signature = generate_signature(body_json)

      response = connection.send(method) do |req|
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

    def extract_error_message(response)
      return "Unknown error" unless response.body.is_a?(Hash)

      response.body["error"]["message"] || "API error"
    rescue
      "Unknown error"
    end

    def extract_error_code(response)
      return nil unless response.body.is_a?(Hash)

      response.body["error"]["code"]
    rescue
      nil
    end

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
