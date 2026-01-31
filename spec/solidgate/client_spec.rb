# frozen_string_literal: true

RSpec.describe Solidgate::Client do
  let(:public_key) { "test_public_key_32chars_long1234" }
  let(:private_key) { "test_private_key_32chars_long123" }
  let(:api_url) { "https://subscriptions.solidgate.com" }

  let(:client) do
    described_class.new(
      public_key: public_key,
      private_key: private_key,
      sandbox: true
    )
  end

  let(:success_response) { { "status" => "success", "id" => "payment_123" } }

  # Disable VCR for these tests since we're using WebMock stubs directly
  around do |example|
    VCR.turned_off { example.run }
  end

  before do
    stub_request(:any, /subscriptions\.solidgate\.com/).to_return(
      status: 200,
      body: success_response.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  describe "#initialize" do
    context "with valid configuration" do
      it "creates a client instance" do
        expect(client).to be_a(described_class)
      end

      it "stores the configuration" do
        expect(client.config.public_key).to eq(public_key)
        expect(client.config.private_key).to eq(private_key)
      end
    end

    context "with Configuration object" do
      it "accepts a Configuration instance" do
        config = Solidgate::Configuration.new
        config.public_key = public_key
        config.private_key = private_key

        client = described_class.new(config)
        expect(client.config).to eq(config)
      end
    end

    context "with missing public_key" do
      it "raises ConfigurationError" do
        expect do
          described_class.new(private_key: private_key)
        end.to raise_error(Solidgate::ConfigurationError, "public_key is required")
      end
    end

    context "with missing private_key" do
      it "raises ConfigurationError" do
        expect do
          described_class.new(public_key: public_key)
        end.to raise_error(Solidgate::ConfigurationError, "private_key is required")
      end
    end
  end

  describe "constants" do
    it "defines IV_LENGTH as 16" do
      expect(described_class::IV_LENGTH).to eq(16)
    end

    it "defines KEY_LENGTH as 32" do
      expect(described_class::KEY_LENGTH).to eq(32)
    end
  end

  # ==================== Payment Methods ====================

  describe "#create_payment" do
    let(:payment_params) do
      {
        order_id: "order_123",
        amount: 1000,
        currency: "USD"
      }
    end

    it "sends POST request to /v1/charge" do
      client.create_payment(payment_params)

      expect(WebMock).to have_requested(:post, "https://subscriptions.solidgate.com/v1/charge")
        .with(body: payment_params.to_json)
    end

    it "includes Merchant header with public key" do
      client.create_payment(payment_params)

      expect(WebMock).to have_requested(:post, "https://subscriptions.solidgate.com/v1/charge")
        .with(headers: { "Merchant" => public_key })
    end

    it "includes Signature header" do
      client.create_payment(payment_params)

      expect(WebMock).to have_requested(:post, "https://subscriptions.solidgate.com/v1/charge")
        .with { |req| !req.headers["Signature"].nil? && !req.headers["Signature"].empty? }
    end

    it "returns parsed response" do
      result = client.create_payment(payment_params)
      expect(result).to eq(success_response)
    end
  end

  describe "#get_payment" do
    let(:payment_id) { "payment_123" }

    it "sends GET request to /v1/charge/:payment_id" do
      client.get_payment(payment_id)

      expect(WebMock).to have_requested(:get, "https://subscriptions.solidgate.com/v1/charge/#{payment_id}")
    end

    it "returns payment details" do
      result = client.get_payment(payment_id)
      expect(result).to eq(success_response)
    end
  end

  describe "#capture_payment" do
    let(:payment_id) { "payment_123" }

    it "sends POST request to /v1/charge/:payment_id/capture" do
      client.capture_payment(payment_id)

      expect(WebMock).to have_requested(:post, "https://subscriptions.solidgate.com/v1/charge/#{payment_id}/capture")
    end

    it "sends capture params when provided" do
      capture_params = { amount: 500 }
      client.capture_payment(payment_id, capture_params)

      expect(WebMock).to have_requested(:post, "https://subscriptions.solidgate.com/v1/charge/#{payment_id}/capture")
        .with(body: capture_params.to_json)
    end

    it "returns capture response" do
      result = client.capture_payment(payment_id)
      expect(result).to eq(success_response)
    end
  end

  describe "#void_payment" do
    let(:payment_id) { "payment_123" }

    it "sends POST request to /v1/charge/:payment_id/void" do
      client.void_payment(payment_id)

      expect(WebMock).to have_requested(:post, "https://subscriptions.solidgate.com/v1/charge/#{payment_id}/void")
    end

    it "returns void response" do
      result = client.void_payment(payment_id)
      expect(result).to eq(success_response)
    end
  end

  describe "#refund_payment" do
    let(:payment_id) { "payment_123" }

    it "sends POST request to /v1/charge/:payment_id/refund" do
      client.refund_payment(payment_id)

      expect(WebMock).to have_requested(:post, "https://subscriptions.solidgate.com/v1/charge/#{payment_id}/refund")
    end

    it "sends refund params when provided" do
      refund_params = { amount: 500, reason: "Customer request" }
      client.refund_payment(payment_id, refund_params)

      expect(WebMock).to have_requested(:post, "https://subscriptions.solidgate.com/v1/charge/#{payment_id}/refund")
        .with(body: refund_params.to_json)
    end

    it "returns refund response" do
      result = client.refund_payment(payment_id)
      expect(result).to eq(success_response)
    end
  end

  # ==================== Subscription Methods ====================

  describe "#create_subscription" do
    let(:subscription_params) do
      {
        product_id: "prod_123",
        customer_account_id: "customer_456",
        order_id: "order_789"
      }
    end

    it "sends POST request to /v1/subscription" do
      client.create_subscription(subscription_params)

      expect(WebMock).to have_requested(:post, "https://subscriptions.solidgate.com/v1/subscription")
        .with(body: subscription_params.to_json)
    end

    it "returns subscription response" do
      result = client.create_subscription(subscription_params)
      expect(result).to eq(success_response)
    end
  end

  describe "#subscription_status" do
    let(:subscription_id) { "sub_123" }

    it "sends POST request to /api/v1/subscription/status" do
      client.subscription_status(subscription_id)

      expect(WebMock).to have_requested(:post, "https://subscriptions.solidgate.com/api/v1/subscription/status")
        .with(body: { subscription_id: subscription_id }.to_json)
    end

    it "returns subscription details" do
      result = client.subscription_status(subscription_id)
      expect(result).to eq(success_response)
    end
  end

  describe "#switch_subscription_product" do
    let(:switch_params) do
      {
        subscription_id: "sub_123",
        new_product_id: "prod_premium_456"
      }
    end

    it "sends POST request to /api/v1/subscription/switch-subscription-product" do
      client.switch_subscription_product(switch_params)

      expect(WebMock).to have_requested(:post, "https://subscriptions.solidgate.com/api/v1/subscription/switch-subscription-product")
        .with(body: switch_params.to_json)
    end

    it "returns update response" do
      result = client.switch_subscription_product(switch_params)
      expect(result).to eq(success_response)
    end
  end

  describe "#update_subscription_pause" do
    let(:subscription_id) { "sub_123" }
    let(:pause_params) { { resume_at: "2026-03-01T00:00:00Z" } }

    it "sends PATCH request to /api/v1/subscriptions/:id/pause-schedule" do
      client.update_subscription_pause(subscription_id, pause_params)

      expect(WebMock).to have_requested(:patch, "https://subscriptions.solidgate.com/api/v1/subscriptions/#{subscription_id}/pause-schedule")
        .with(body: pause_params.to_json)
    end

    it "returns updated pause schedule" do
      result = client.update_subscription_pause(subscription_id, pause_params)
      expect(result).to eq(success_response)
    end
  end

  describe "#create_subscription_pause" do
    let(:subscription_id) { "sub_123" }
    let(:pause_params) do
      {
        pause_at: "2026-02-01T00:00:00Z",
        resume_at: "2026-03-01T00:00:00Z"
      }
    end

    it "sends POST request to /api/v1/subscriptions/:id/pause-schedule" do
      client.create_subscription_pause(subscription_id, pause_params)

      expect(WebMock).to have_requested(:post, "https://subscriptions.solidgate.com/api/v1/subscriptions/#{subscription_id}/pause-schedule")
        .with(body: pause_params.to_json)
    end

    it "returns created pause schedule" do
      result = client.create_subscription_pause(subscription_id, pause_params)
      expect(result).to eq(success_response)
    end
  end

  describe "#delete_subscription_pause" do
    let(:subscription_id) { "sub_123" }

    it "sends DELETE request to /api/v1/subscriptions/:id/pause-schedule" do
      client.delete_subscription_pause(subscription_id)

      expect(WebMock).to have_requested(:delete, "https://subscriptions.solidgate.com/api/v1/subscriptions/#{subscription_id}/pause-schedule")
    end

    it "returns confirmation response" do
      result = client.delete_subscription_pause(subscription_id)
      expect(result).to eq(success_response)
    end
  end

  describe "#cancel_subscription" do
    let(:cancel_params) do
      {
        subscription_id: "sub_123",
        cancel_at_period_end: true,
        reason: "Customer requested"
      }
    end

    it "sends POST request to /api/v1/subscription/cancel" do
      client.cancel_subscription(cancel_params)

      expect(WebMock).to have_requested(:post, "https://subscriptions.solidgate.com/api/v1/subscription/cancel")
        .with(body: cancel_params.to_json)
    end

    it "returns cancellation response" do
      result = client.cancel_subscription(cancel_params)
      expect(result).to eq(success_response)
    end
  end

  # ==================== Product Methods ====================

  describe "#create_product" do
    let(:product_params) do
      {
        name: "Premium Plan",
        description: "Access to premium features",
        type: "subscription"
      }
    end

    it "sends POST request to /api/v1/products" do
      client.create_product(product_params)

      expect(WebMock).to have_requested(:post, "https://subscriptions.solidgate.com/api/v1/products")
        .with(body: product_params.to_json)
    end

    it "returns created product" do
      result = client.create_product(product_params)
      expect(result).to eq(success_response)
    end
  end

  describe "#create_price" do
    let(:product_id) { "prod_123" }
    let(:price_params) do
      {
        amount: 1999,
        currency: "USD",
        interval: "month"
      }
    end

    it "sends POST request to /api/v1/products/:id/prices" do
      client.create_price(product_id, price_params)

      expect(WebMock).to have_requested(:post, "https://subscriptions.solidgate.com/api/v1/products/#{product_id}/prices")
        .with(body: price_params.to_json)
    end

    it "returns created price" do
      result = client.create_price(product_id, price_params)
      expect(result).to eq(success_response)
    end
  end

  describe "#products" do
    it "sends GET request to /api/v1/products" do
      client.products

      expect(WebMock).to have_requested(:get, "https://subscriptions.solidgate.com/api/v1/products")
    end

    it "returns list of products" do
      result = client.products
      expect(result).to eq(success_response)
    end
  end

  describe "#product_prices" do
    let(:product_id) { "prod_123" }

    it "sends GET request to /api/v1/products/:id/prices" do
      client.product_prices(product_id)

      expect(WebMock).to have_requested(:get, "https://subscriptions.solidgate.com/api/v1/products/#{product_id}/prices")
    end

    it "returns list of prices" do
      result = client.product_prices(product_id)
      expect(result).to eq(success_response)
    end
  end

  # ==================== Intent & Signature Methods ====================

  describe "#generate_intent" do
    let(:intent_params) do
      { order_id: "order_123", product_id: "prod_456" }.to_json
    end

    it "returns an encrypted string" do
      result = client.generate_intent(intent_params)
      expect(result).to be_a(String)
    end

    it "returns Base64-encoded content" do
      result = client.generate_intent(intent_params)
      # URL-safe Base64 should not contain + or /
      expect(result).not_to include("+")
      expect(result).not_to include("/")
    end

    it "produces different output for different inputs" do
      result1 = client.generate_intent({ order_id: "order_1" }.to_json)
      result2 = client.generate_intent({ order_id: "order_2" }.to_json)
      expect(result1).not_to eq(result2)
    end

    it "produces different output each time due to random IV" do
      result1 = client.generate_intent(intent_params)
      result2 = client.generate_intent(intent_params)
      expect(result1).not_to eq(result2)
    end
  end

  describe "#generate_signature" do
    let(:json_payload) { '{"order_id":"123"}' }

    it "returns a Base64-encoded string" do
      signature = client.generate_signature(json_payload)
      expect { Base64.strict_decode64(signature) }.not_to raise_error
    end

    it "generates consistent signature for same input" do
      signature1 = client.generate_signature(json_payload)
      signature2 = client.generate_signature(json_payload)
      expect(signature1).to eq(signature2)
    end

    it "generates different signatures for different inputs" do
      signature1 = client.generate_signature('{"order_id":"123"}')
      signature2 = client.generate_signature('{"order_id":"456"}')
      expect(signature1).not_to eq(signature2)
    end

    it "accepts custom public_key and private_key" do
      custom_signature = client.generate_signature(
        json_payload,
        public_key: "custom_public",
        private_key: "custom_private"
      )

      default_signature = client.generate_signature(json_payload)
      expect(custom_signature).not_to eq(default_signature)
    end

    it "uses HMAC-SHA512 algorithm" do
      # Manually compute expected signature
      digest = OpenSSL::Digest.new("sha512")
      hmac = OpenSSL::HMAC.new(private_key, digest)
      hmac.update(public_key + json_payload + public_key)
      expected = Base64.strict_encode64(hmac.hexdigest)

      expect(client.generate_signature(json_payload)).to eq(expected)
    end
  end

  # ==================== Error Handling ====================
  # Note: The client wraps API errors in a generic Solidgate::Error due to the rescue => e block.
  # These tests verify the actual behavior of the error handling.

  describe "error handling" do
    let(:payment_params) { { order_id: "order_123", amount: 1000 } }

    context "when API returns 400" do
      before do
        WebMock.reset!
        stub_request(:post, /subscriptions\.solidgate\.com/).to_return(
          status: 400,
          body: { error: { message: "Invalid parameters", code: "invalid_params" } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "raises an error" do
        expect { client.create_payment(payment_params) }.to raise_error(Solidgate::Error)
      end

      it "includes error message in the wrapped error" do
        expect { client.create_payment(payment_params) }.to raise_error do |error|
          expect(error.message).to include("Invalid parameters")
        end
      end
    end

    context "when API returns 401" do
      before do
        WebMock.reset!
        stub_request(:post, /subscriptions\.solidgate\.com/).to_return(
          status: 401,
          body: { error: { message: "Unauthorized" } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "raises an error" do
        expect { client.create_payment(payment_params) }.to raise_error(Solidgate::Error)
      end

      it "includes authentication failed message" do
        expect { client.create_payment(payment_params) }.to raise_error do |error|
          expect(error.message).to include("Authentication failed")
        end
      end
    end

    context "when API returns 429" do
      before do
        WebMock.reset!
        stub_request(:post, /subscriptions\.solidgate\.com/).to_return(
          status: 429,
          body: { error: { message: "Too many requests" } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "raises an error" do
        expect { client.create_payment(payment_params) }.to raise_error(Solidgate::Error)
      end

      it "includes rate limit message" do
        expect { client.create_payment(payment_params) }.to raise_error do |error|
          expect(error.message).to include("Rate limit exceeded")
        end
      end
    end

    context "when API returns 500" do
      before do
        WebMock.reset!
        stub_request(:post, /subscriptions\.solidgate\.com/).to_return(
          status: 500,
          body: { error: { message: "Internal server error" } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "raises an error" do
        expect { client.create_payment(payment_params) }.to raise_error(Solidgate::Error)
      end

      it "includes server error message" do
        expect { client.create_payment(payment_params) }.to raise_error do |error|
          expect(error.message).to include("Server error")
        end
      end
    end

    context "when API returns unknown status" do
      before do
        WebMock.reset!
        stub_request(:post, /subscriptions\.solidgate\.com/).to_return(
          status: 418,
          body: {}.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "raises an error with unknown error message" do
        expect { client.create_payment(payment_params) }.to raise_error(Solidgate::Error) do |error|
          expect(error.message).to include("Unknown error")
        end
      end
    end

    context "when connection times out" do
      before do
        WebMock.reset!
        stub_request(:post, /subscriptions\.solidgate\.com/).to_timeout
      end

      it "raises a connection-related error" do
        expect { client.create_payment(payment_params) }.to raise_error(Solidgate::Error)
      end
    end

    context "when connection fails" do
      before do
        WebMock.reset!
        stub_request(:post, /subscriptions\.solidgate\.com/).to_raise(Faraday::ConnectionFailed.new("Connection refused"))
      end

      it "raises ConnectionError" do
        expect { client.create_payment(payment_params) }.to raise_error(Solidgate::ConnectionError)
      end

      it "includes connection failure message" do
        expect { client.create_payment(payment_params) }.to raise_error do |error|
          expect(error.message).to include("Connection failed")
        end
      end
    end
  end

  # ==================== Request Headers ====================

  describe "request headers" do
    let(:payment_params) { { order_id: "order_123" } }

    it "includes Accept header" do
      client.create_payment(payment_params)

      expect(WebMock).to have_requested(:post, /subscriptions\.solidgate\.com/)
        .with(headers: { "Accept" => "application/json" })
    end

    it "includes Content-Type header" do
      client.create_payment(payment_params)

      expect(WebMock).to have_requested(:post, /subscriptions\.solidgate\.com/)
        .with(headers: { "Content-Type" => "application/json" })
    end

    it "includes User-Agent header" do
      client.create_payment(payment_params)

      expect(WebMock).to have_requested(:post, /subscriptions\.solidgate\.com/)
        .with { |req| req.headers["User-Agent"].include?("Solidgate") }
    end

    it "includes Merchant header with public key" do
      client.create_payment(payment_params)

      expect(WebMock).to have_requested(:post, /subscriptions\.solidgate\.com/)
        .with(headers: { "Merchant" => public_key })
    end

    it "includes Signature header" do
      client.create_payment(payment_params)

      expect(WebMock).to have_requested(:post, /subscriptions\.solidgate\.com/)
        .with { |req| !req.headers["Signature"].nil? && !req.headers["Signature"].empty? }
    end
  end

  # ==================== Sandbox Mode ====================

  describe "sandbox mode" do
    context "when sandbox is true" do
      let(:sandbox_client) do
        described_class.new(
          public_key: public_key,
          private_key: private_key,
          sandbox: true
        )
      end

      it "uses sandbox API URL" do
        sandbox_client.products
        expect(WebMock).to have_requested(:get, /subscriptions\.solidgate\.com/)
      end
    end

    context "when sandbox is false" do
      let(:production_client) do
        described_class.new(
          public_key: public_key,
          private_key: private_key,
          sandbox: false
        )
      end

      it "uses production API URL" do
        production_client.products
        expect(WebMock).to have_requested(:get, /subscriptions\.solidgate\.com/)
      end
    end
  end
end
