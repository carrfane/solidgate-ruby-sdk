# frozen_string_literal: true

RSpec.describe Solidgate do
  it "has a version number" do
    expect(Solidgate::VERSION).not_to be nil
  end

  describe ".configure" do
    it "yields the configuration object" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(Solidgate::Configuration)
    end

    it "configures the client" do
      described_class.configure do |config|
        config.public_key = "test_public_key"
        config.private_key = "test_private_key"
        config.sandbox = true
      end

      expect(described_class.configuration.public_key).to eq("test_public_key")
      expect(described_class.configuration.private_key).to eq("test_private_key")
      expect(described_class.configuration.sandbox).to be true
    end
  end

  describe ".client" do
    before do
      described_class.configure do |config|
        config.public_key = "test_public_key"
        config.private_key = "test_private_key"
        config.sandbox = true
      end
    end

    it "returns a new client instance" do
      client = described_class.client
      expect(client).to be_a(Solidgate::Client)
    end

    it "accepts configuration options" do
      client = described_class.client(public_key: "custom_key", private_key: "custom_private", sandbox: false)
      expect(client.config.public_key).to eq("custom_key")
      expect(client.config.private_key).to eq("custom_private")
      expect(client.config.sandbox).to be false
    end
  end
end
