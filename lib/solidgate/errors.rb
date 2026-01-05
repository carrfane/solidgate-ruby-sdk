# frozen_string_literal: true

module Solidgate
  # Base error class for all Solidgate errors
  class Error < StandardError
    attr_reader :code, :details

    def initialize(message = nil, code = nil, details = nil)
      super(message)
      @code = code
      @details = details
    end
  end

  # Configuration error
  class ConfigurationError < Error; end

  # API error
  class APIError < Error
    def initialize(message, code, details = nil, http_status = nil)
      super(message, code, details)
      @http_status = http_status
    end

    attr_reader :http_status
  end

  # Authentication error
  class AuthenticationError < APIError; end

  # Invalid request error
  class InvalidRequestError < APIError; end

  # Connection error
  class ConnectionError < Error; end

  # Timeout error
  class TimeoutError < Error; end

  # Rate limit error
  class RateLimitError < APIError; end

  # Validation error
  class ValidationError < Error
    attr_reader :errors

    def initialize(message, errors = {})
      super(message)
      @errors = errors
    end
  end
end
