# frozen_string_literal: true

require_relative "solidgate/version"
require_relative "solidgate/configuration"
require_relative "solidgate/errors"
require_relative "solidgate/client"
require_relative "solidgate/payment"
require_relative "solidgate/webhook"

module Solidgate
  class << self
    # Configure the Solidgate client
    #
    # @yield [Configuration] configuration object
    # @example
    #   Solidgate.configure do |config|
    #     config.public_key = "your_public_key"
    #     config.private_key = "your_private_key"
    #     config.sandbox = true
    #   end
    def configure
      yield(configuration)
    end

    # Current configuration
    #
    # @return [Configuration] current configuration
    def configuration
      @configuration ||= Configuration.new
    end

    # Create a new client instance
    #
    # @param options [Hash] optional configuration overrides
    # @return [Client] new client instance
    def client(options = Solidgate.configuration)
      Client.new(options)
    end
  end
end
