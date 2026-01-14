# frozen_string_literal: true

require_relative "../lib/solidgate-ruby-sdk"
require "webmock/rspec"
require "vcr"

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

# Configure VCR
VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.ignore_localhost = true
  
  # Filter sensitive data
  config.filter_sensitive_data('<PUBLIC_KEY>') { ENV['SOLIDGATE_PUBLIC_KEY'] }
  config.filter_sensitive_data('<PRIVATE_KEY>') { ENV['SOLIDGATE_PRIVATE_KEY'] }
  config.filter_sensitive_data('<SIGNATURE>') do |interaction|
    interaction.request.headers['Signature']&.first
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset configuration before each test
  config.before(:each) do
    Solidgate.instance_variable_set(:@configuration, nil)
  end

  # Helper method to configure Solidgate for tests
  config.before(:each, :configured) do
    Solidgate.configure do |c|
      c.public_key = "test_public_key"
      c.private_key = "test_private_key"
      c.sandbox = true
    end
  end
end
