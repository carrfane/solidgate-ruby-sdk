#!/usr/bin/env ruby
# frozen_string_literal: true

# Example usage of the Solidgate Ruby SDK

require_relative "../lib/solidgate"

# Configure the SDK
Solidgate.configure do |config|
  config.public_key = ENV["SOLIDGATE_PUBLIC_KEY"] || "your_public_key_here"
  config.private_key = ENV["SOLIDGATE_PRIVATE_KEY"] || "your_private_key_here"
  config.sandbox = true # Use sandbox for testing
end

begin
  # Create a payment instance
  payment = Solidgate::Payment.new

  puts "=== Creating a Payment ==="
  
  # Create a new payment
  payment_params = {
    order_id: "example_order_#{Time.now.to_i}",
    amount: 1000, # $10.00 in cents
    currency: "USD",
    card_data: {
      number: "4111111111111111",      # Test card number
      exp_month: "12",
      exp_year: "2025",
      cvv: "123"
    },
    customer: {
      email: "customer@example.com",
      first_name: "John",
      last_name: "Doe"
    },
    description: "Test payment from Ruby SDK example"
  }
  
  payment_response = payment.create(payment_params)
  puts "Payment created successfully!"
  puts "Payment ID: #{payment_response['payment_id']}"
  puts "Status: #{payment_response['status']}"
  
  payment_id = payment_response["payment_id"]
  
  # Get payment details
  puts "\n=== Getting Payment Details ==="
  payment_details = payment.get(payment_id)
  puts "Payment Amount: #{payment_details['amount']}"
  puts "Payment Status: #{payment_details['status']}"
  
  # Capture the payment (if it was authorized)
  if payment_details["status"] == "authorized"
    puts "\n=== Capturing Payment ==="
    capture_response = payment.capture(payment_id)
    puts "Payment captured successfully!"
    puts "Capture Status: #{capture_response['status']}"
  end
  
  # Example of partial refund
  if payment_details["status"] == "captured" || payment_details["status"] == "succeeded"
    puts "\n=== Refunding Payment (Partial) ==="
    refund_response = payment.refund(payment_id, amount: 500, reason: "Partial refund example")
    puts "Refund processed successfully!"
    puts "Refund Amount: #{refund_response['amount']}"
    puts "Refund Status: #{refund_response['status']}"
  end

rescue Solidgate::ValidationError => e
  puts "❌ Validation Error: #{e.message}"
  puts "Errors: #{e.errors}"
rescue Solidgate::AuthenticationError => e
  puts "❌ Authentication Error: #{e.message}"
  puts "Please check your API credentials"
rescue Solidgate::APIError => e
  puts "❌ API Error: #{e.message}"
  puts "Error Code: #{e.code}" if e.code
  puts "HTTP Status: #{e.http_status}" if e.http_status
rescue Solidgate::ConnectionError => e
  puts "❌ Connection Error: #{e.message}"
  puts "Please check your internet connection"
rescue Solidgate::Error => e
  puts "❌ Solidgate Error: #{e.message}"
rescue => e
  puts "❌ Unexpected Error: #{e.message}"
  puts e.backtrace if ENV["DEBUG"]
end
