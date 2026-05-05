# Solidgate Ruby SDK Integration Guide (Payments)

> Target version: `solidgate-ruby-sdk` `0.2.0`  
> Audience: engineers and LLM agents integrating Solidgate payments in Ruby apps.

## 1) What this SDK provides

Core entrypoints:

- `Solidgate.configure` for global credentials/config
- `Solidgate::Client` as the low-level API client (recommended for full control)
- `Solidgate::Payment` as a higher-level payment wrapper
- `Solidgate::Webhook` for webhook signature validation

Main domains used by the SDK:

- `https://subscriptions.solidgate.com` (default API base)
- `https://pay.solidgate.com` (refund/order-status/recurring card flows)
- `https://gate.solidgate.com` (alternative refund/APM recurring flows)

---

## 2) Install and initialize

### Gem installation

```ruby
# Gemfile
gem "solidgate-ruby-sdk"
```

Then:

```bash
bundle install
```

### Require and configure

```ruby
require "solidgate-ruby-sdk"

Solidgate.configure do |config|
  config.public_key = ENV.fetch("SOLIDGATE_PUBLIC_KEY")
  config.private_key = ENV.fetch("SOLIDGATE_PRIVATE_KEY")
  config.webhook_public_key = ENV["SOLIDGATE_WEBHOOK_PUBLIC_KEY"]
  config.webhook_private_key = ENV["SOLIDGATE_WEBHOOK_PRIVATE_KEY"]

  # Optional
  config.sandbox = true
  config.timeout = 30
  config.open_timeout = 10
  # config.api_url = "https://custom.example.com" # optional override
end
```

Environment variables commonly used:

- `SOLIDGATE_PUBLIC_KEY`
- `SOLIDGATE_PRIVATE_KEY`
- `SOLIDGATE_WEBHOOK_PUBLIC_KEY`
- `SOLIDGATE_WEBHOOK_PRIVATE_KEY`

---

## 3) Quick start payment flow

Use `Solidgate::Client` directly for integration scripts and backend services.

```ruby
client = Solidgate::Client.new

# 1) Create charge
created = client.create_payment(
  order_id: "order_123",
  amount: 1000,       # minor units (e.g., cents)
  currency: "USD",
  customer_email: "customer@example.com"
)

payment_id = created["id"] || created["payment_id"]

# 2) Get payment details/status
payment = client.get_payment(payment_id)

# 3a) Capture (for auth flow)
captured = client.capture_payment(payment_id)
# or partial capture
# captured = client.capture_payment(payment_id, amount: 500)

# 3b) Void (if authorized and not captured)
# voided = client.void_payment(payment_id)

# 3c) Refund by payment_id
refunded = client.refund_payment(payment_id, amount: 300, reason: "partial_refund")
```

---

## 4) API methods relevant for payments

### Charges (`subscriptions.solidgate.com`)

- `create_payment(params)` -> `POST /v1/charge`
- `get_payment(payment_id)` -> `GET /v1/charge/:payment_id`
- `capture_payment(payment_id, params = {})` -> `POST /v1/charge/:payment_id/capture`
- `void_payment(payment_id)` -> `POST /v1/charge/:payment_id/void`
- `refund_payment(payment_id, params = {})` -> `POST /v1/charge/:payment_id/refund`

### Refund and status helper routes

- `refund(params)` -> `POST https://pay.solidgate.com/api/v1/refund`
  - typically `order_id`, optional `amount`
- `order_status(params)` -> `POST https://pay.solidgate.com/api/v1/status`
- `apm_order_status(params)` -> `POST https://gate.solidgate.com/api/v1/status`

### Alternative payment routes

- `alt_refund(params)` -> `POST https://gate.solidgate.com/api/v1/refund`
- `make_card_recurring(params)` -> `POST https://pay.solidgate.com/api/v1/recurring`
- `make_apm_recurring(params)` -> `POST https://gate.solidgate.com/api/v1/recurring`

---

## 5) Frontend payment intent flow (server-side generation)

For hosted/payment-form flows, generate encrypted intent and signature server-side.

```ruby
client = Solidgate::Client.new

intent_json = {
  order_id: "order_123",
  product_id: "product_456",
  customer_account_id: "cust_789",
  order_description: "Premium plan",
  type: "auth",           # or "sale"
  settle_interval: 0,
  retry_attempt: 3,
  language: "en"
}.to_json

payment_intent = client.generate_intent(intent_json)

payment_data = {
  merchant: Solidgate.configuration.public_key,
  signature: client.generate_signature(payment_intent),
  paymentIntent: payment_intent
}
```

Return `payment_data` to the frontend that initializes Solidgate JS.

---

## 6) Webhook verification

Always validate signature before parsing/trusting webhook payload.

```ruby
payload = request.body.read
signature = request.headers["Signature"]

webhook = Solidgate::Webhook.new

unless webhook.validate_signature(payload, signature)
  head :unauthorized
  return
end

event = JSON.parse(payload)
# process event
```

---

## 7) Error handling

SDK error classes:

- `Solidgate::Error`
- `Solidgate::ConfigurationError`
- `Solidgate::ValidationError`
- `Solidgate::AuthenticationError`
- `Solidgate::InvalidRequestError`
- `Solidgate::APIError`
- `Solidgate::ConnectionError`
- `Solidgate::TimeoutError`
- `Solidgate::RateLimitError`

Recommended handling pattern:

```ruby
begin
  client.create_payment(order_id: "o1", amount: 1000, currency: "USD")
rescue Solidgate::ValidationError => e
  # local validation (wrapper-level)
rescue Solidgate::ConnectionError, Solidgate::TimeoutError => e
  # network/retry logic
rescue Solidgate::APIError => e
  # inspect e.code, e.http_status, e.details
rescue Solidgate::Error => e
  # fallback
end
```

---

## 8) Auth/signing model used by this SDK

Each request includes:

- `Merchant: <public_key>`
- `Signature: <generated_signature>`
- `Content-Type: application/json`

Signature generation in this SDK:

1. Serialize body to JSON string (empty string for no body)
2. Build message: `public_key + json_string + public_key`
3. HMAC-SHA512 with `private_key`
4. Base64-encode the hex digest string

Use SDK-generated signatures instead of re-implementing to avoid mismatch.

---

## 9) LLM-agent integration playbook

If an LLM agent is integrating this SDK into another project, follow this sequence:

1. Add `gem "solidgate-ruby-sdk"` and install dependencies.
2. Create initializer with `Solidgate.configure`.
3. Add a service object wrapping `Solidgate::Client` for:
   - create/get/capture/void/refund
4. Add idempotency/order-id strategy in app layer.
5. Implement webhook endpoint with signature validation first.
6. Add retries for `ConnectionError`/`TimeoutError` and safe backoff.
7. Add structured logs with:
   - `order_id`, `payment_id`, `status`, error code/status
8. Add integration tests with WebMock/VCR style stubs.
9. Add runbooks for capture/refund/manual reconciliation.

---

## 10) Known quirks in current SDK (v0.2.0)

- `settle_payment` currently does **not** call an API endpoint; it returns `config.api_url`.
- `README.md` examples may not fully match actual method signatures in code.
- `Solidgate::Payment#refund` refunds by `order_id` through `client.refund`, not by `payment_id`.
- Sandbox and production constants currently point to the same URL in config.
- Broad rescue in request pipeline may wrap some API exceptions into `Solidgate::Error` depending on failure path.

For robust integrations, prefer `Solidgate::Client` and explicitly test your payment flows.

---

## 11) Minimal production checklist

- [ ] Credentials loaded from secure env/secret manager
- [ ] Webhook signature validation enabled
- [ ] Retries/backoff for transient failures
- [ ] Monitoring for failed captures/refunds
- [ ] Reconciliation job using `order_status`
- [ ] Alerting on repeated auth/429/5xx errors
- [ ] Test mode and live mode credentials isolated
