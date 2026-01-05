module Solidgate
  class Webhook
    # Webhook resource for handling webhook-related operations
    attr_reader :client

    def initialize(client = nil)
      @client = client || Solidgate.client
    end

    # Validate webhook signature
    # @param payload [String] webhook payload
    # @param signature [String] webhook signature
    # @return [Boolean] whether the signature is valid
    def validate_signature(payload, signature)
      client.generate_signature(payload,
                                 public_key: Solidgate.configuration.webhook_public_key,
                                 private_key: Solidgate.configuration.webhook_private_key) == signature
    end
  end
end
