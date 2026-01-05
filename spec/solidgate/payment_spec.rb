# frozen_string_literal: true

RSpec.describe Solidgate::Payment, :configured do
  let(:payment) { described_class.new }
  let(:client) { instance_double(Solidgate::Client) }

  before do
    allow(Solidgate).to receive(:client).and_return(client)
  end

  describe "#create" do
    let(:valid_params) do
      {
        order_id: "order_123",
        amount: 1000,
        currency: "USD",
        card_data: {
          number: "4111111111111111",
          exp_month: "12",
          exp_year: "2025",
          cvv: "123"
        }
      }
    end

    context "with valid parameters" do
      it "creates a payment" do
        expect(client).to receive(:create_payment).with(valid_params)
        payment.create(valid_params)
      end
    end

    context "with missing order_id" do
      it "raises ValidationError" do
        params = valid_params.except(:order_id)
        expect { payment.create(params) }.to raise_error(Solidgate::ValidationError) do |error|
          expect(error.errors[:order_id]).to eq("is required")
        end
      end
    end

    context "with missing amount" do
      it "raises ValidationError" do
        params = valid_params.except(:amount)
        expect { payment.create(params) }.to raise_error(Solidgate::ValidationError) do |error|
          expect(error.errors[:amount]).to eq("is required")
        end
      end
    end

    context "with invalid amount" do
      it "raises ValidationError" do
        params = valid_params.merge(amount: 0)
        expect { payment.create(params) }.to raise_error(Solidgate::ValidationError) do |error|
          expect(error.errors[:amount]).to eq("must be greater than 0")
        end
      end
    end

    context "with invalid currency" do
      it "raises ValidationError" do
        params = valid_params.merge(currency: "US")
        expect { payment.create(params) }.to raise_error(Solidgate::ValidationError) do |error|
          expect(error.errors[:currency]).to eq("must be a 3-letter currency code")
        end
      end
    end
  end

  describe "#get" do
    context "with valid payment_id" do
      it "retrieves payment information" do
        expect(client).to receive(:get_payment).with("payment_123")
        payment.get("payment_123")
      end
    end

    context "with empty payment_id" do
      it "raises ArgumentError" do
        expect { payment.get("") }.to raise_error(ArgumentError, "payment_id is required")
      end
    end

    context "with nil payment_id" do
      it "raises ArgumentError" do
        expect { payment.get(nil) }.to raise_error(ArgumentError, "payment_id is required")
      end
    end
  end

  describe "#capture" do
    it "captures a payment" do
      expect(client).to receive(:capture_payment).with("payment_123", {})
      payment.capture("payment_123")
    end

    it "captures with specific amount" do
      expect(client).to receive(:capture_payment).with("payment_123", { amount: 500 })
      payment.capture("payment_123", amount: 500)
    end
  end

  describe "#void" do
    it "voids a payment" do
      expect(client).to receive(:void_payment).with("payment_123")
      payment.void("payment_123")
    end
  end

  describe "#refund" do
    it "refunds a payment" do
      expect(client).to receive(:refund_payment).with("payment_123", {})
      payment.refund("payment_123")
    end

    it "refunds with specific amount and reason" do
      expect(client).to receive(:refund_payment).with("payment_123", { amount: 500, reason: "Customer request" })
      payment.refund("payment_123", amount: 500, reason: "Customer request")
    end
  end
end
