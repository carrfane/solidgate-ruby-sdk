# frozen_string_literal: true

module Solidgate
  # Configuration class for the Solidgate SDK
  class Configuration
    # @!attribute [rw] public_key
    #   @return [String] Solidgate public key
    attr_accessor :public_key

    # @!attribute [rw] private_key
    #   @return [String] Solidgate private key
    attr_accessor :private_key

    # @!attribute [rw] sandbox
    #   @return [Boolean] whether to use sandbox environment
    attr_accessor :sandbox

    # @!attribute [rw] api_url
    #   @return [String] API base URL
    attr_accessor :api_url

    # @!attribute [rw] timeout
    #   @return [Integer] request timeout in seconds
    attr_accessor :timeout

    # @!attribute [rw] open_timeout
    #   @return [Integer] connection timeout in seconds
    attr_accessor :open_timeout

    # @!attribute [rw] user_agent
    #   @return [String] custom user agent
    attr_accessor :user_agent
    
    # @!attribute [rw] webhook_public_key
    #   @return [String] Webhook public key
    attr_accessor :webhook_public_key

    # @!attribute [rw] webhook_private_key
    #   @return [String] Webhook private key
    attr_accessor :webhook_private_key

    # Production API URL
    PRODUCTION_URL = "https://subscriptions.solidgate.com"

    # Sandbox API URL
    SANDBOX_URL = "https://subscriptions.solidgate.com"

    def initialize
      @sandbox = false
      @timeout = 30
      @open_timeout = 10
      @user_agent = "Solidgate Ruby SDK/#{VERSION}"
    end

    # Get the appropriate API URL based on sandbox setting
    #
    # @return [String] API base URL
    def api_url
      @api_url || (sandbox? ? SANDBOX_URL : PRODUCTION_URL)
    end

    # Check if sandbox mode is enabled
    #
    # @return [Boolean] true if sandbox mode is enabled
    def sandbox?
      @sandbox
    end

    # Validate that required configuration is present
    #
    # @raise [ConfigurationError] if required configuration is missing
    def validate!
      raise ConfigurationError, "public_key is required" unless public_key
      raise ConfigurationError, "private_key is required" unless private_key
    end
  end
end
