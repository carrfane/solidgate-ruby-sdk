# frozen_string_literal: true

module Solidgate
  # Payment resource for handling payment-related operations
  class Payment
    attr_reader :client

    def initialize(client = nil)
      @client = client || Solidgate.client
    end

    # Create a new payment charge
    #
    # @param params [Hash] payment parameters
    # @option params [String] :order_id unique order identifier
    # @option params [Integer] :amount amount in cents
    # @option params [String] :currency currency code (e.g., "USD")
    # @option params [Hash] :card_data card information
    # @option params [Hash] :customer customer information
    # @option params [String] :description payment description
    # @return [Hash] payment response
    def create(params)
      validate_create_params(params)
      client.create_payment(params)
    end

    # Retrieve payment information
    #
    # @param payment_id [String] payment ID
    # @return [Hash] payment details
    def get(payment_id)
      raise ArgumentError, "payment_id is required" if payment_id.nil? || payment_id.empty?
      
      client.get_payment(payment_id)
    end

    # Capture a previously authorized payment
    #
    # @param payment_id [String] payment ID
    # @param amount [Integer] amount to capture in cents (optional, defaults to full amount)
    # @return [Hash] capture response
    def capture(payment_id, amount: nil)
      raise ArgumentError, "payment_id is required" if payment_id.nil? || payment_id.empty?
      
      params = {}
      params[:amount] = amount if amount
      
      client.capture_payment(payment_id, params)
    end

    # Void a payment (cancel an authorization)
    #
    # @param payment_id [String] payment ID
    # @return [Hash] void response
    def void(payment_id)
      raise ArgumentError, "payment_id is required" if payment_id.nil? || payment_id.empty?
      
      client.void_payment(payment_id)
    end

    # Refund a payment (full or partial)
    #
    # @param payment_id [String] payment ID
    # @param amount [Integer] amount to refund in cents (optional, defaults to full amount)
    # @param reason [String] refund reason (optional)
    # @return [Hash] refund response
    def refund(payment_id, amount: nil, reason: nil)
      raise ArgumentError, "payment_id is required" if payment_id.nil? || payment_id.empty?
      
      params = {}
      params[:amount] = amount if amount
      params[:reason] = reason if reason
      
      client.refund_payment(payment_id, params)
    end

    private

    def validate_create_params(params)
      errors = {}

      errors[:order_id] = "is required" unless params[:order_id]
      errors[:amount] = "is required" unless params[:amount]
      errors[:currency] = "is required" unless params[:currency]
      
      if params[:amount] && params[:amount] <= 0
        errors[:amount] = "must be greater than 0"
      end

      if params[:currency] && params[:currency].length != 3
        errors[:currency] = "must be a 3-letter currency code"
      end

      unless errors.empty?
        raise ValidationError.new("Invalid payment parameters", errors)
      end
    end
  end
end
