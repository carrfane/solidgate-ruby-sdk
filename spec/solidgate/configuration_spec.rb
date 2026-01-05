# frozen_string_literal: true

RSpec.describe Solidgate::Configuration do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.sandbox).to be false
      expect(config.timeout).to eq(30)
      expect(config.open_timeout).to eq(10)
      expect(config.user_agent).to include("Solidgate Ruby SDK")
    end
  end

  describe "#api_url" do
    context "when sandbox is false" do
      it "returns production URL" do
        config.sandbox = false
        expect(config.api_url).to eq(Solidgate::Configuration::PRODUCTION_URL)
      end
    end

    context "when sandbox is true" do
      it "returns sandbox URL" do
        config.sandbox = true
        expect(config.api_url).to eq(Solidgate::Configuration::SANDBOX_URL)
      end
    end

    context "when custom api_url is set" do
      it "returns custom URL" do
        custom_url = "https://custom.api.com"
        config.api_url = custom_url
        expect(config.api_url).to eq(custom_url)
      end
    end
  end

  describe "#sandbox?" do
    it "returns sandbox status" do
      expect(config.sandbox?).to be false
      config.sandbox = true
      expect(config.sandbox?).to be true
    end
  end

  describe "#validate!" do
    context "when public_key is missing" do
      it "raises ConfigurationError" do
        config.private_key = "private_key"
        expect { config.validate! }.to raise_error(Solidgate::ConfigurationError, "public_key is required")
      end
    end

    context "when private_key is missing" do
      it "raises ConfigurationError" do
        config.public_key = "public_key"
        expect { config.validate! }.to raise_error(Solidgate::ConfigurationError, "private_key is required")
      end
    end

    context "when both keys are present" do
      it "does not raise error" do
        config.public_key = "public_key"
        config.private_key = "private_key"
        expect { config.validate! }.not_to raise_error
      end
    end
  end
end
