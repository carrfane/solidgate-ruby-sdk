# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.16] - 2026-02-23
### Added
- `alt_refund` endpoint to create refunds using an alternative payment method (`Solidgate::Client#alt_refund`).

## [0.1.13] - 2026-02-13
### Added
- `order_status` endpoint to check order/payment status on `pay.solidgate.com` (`Solidgate::Client#order_status`).
- README: expanded examples and documentation (order status, payment/refund examples).

### Changed
- Documentation and minor client docstring improvements.

## [0.1.12] - 2026-02-13
### Added
- `update_product_price` endpoint (`Solidgate::Client#update_product_price`) to modify product price attributes.

### Changed
- Bumped packaged version to `0.1.12` and updated `Gemfile.lock`.
- Tests updated for product/price management.

## [0.1.11] - 2026-02-06
### Added
- `update_subscription_payment_method` endpoint to update a subscription's stored payment token.
- README examples and RSpec coverage for subscription payment-method updates.

## [0.1.10] - 2026-02-03
- Added refund method example to README

## [0.1.9] - 2026-02-03
- Added documentation for restore_subscription method
- Added restore_subscription to README.md usage examples
- Added tests for restore_subscription method

## [0.1.4] - 2026-01-14
- Client Specs enhancements

## [0.1.3] - 2026-01-13
- Added support for switch subscription product
- Added support for create product
- Added support to create price for product

## [0.1.0] - 2025-12-18

### Added
- Initial release of the Solidgate Ruby SDK
- Payment creation, retrieval, capture, void, and refund functionality
- Subscription management (basic structure)
- Comprehensive error handling with specific error classes
- Configuration management for API credentials and environment settings
- HTTP client with proper authentication and signature generation
- Support for both sandbox and production environments
- RSpec test suite foundation

### Features
- Support for all major payment operations
- Automatic request signing using SHA-1 + Base64
- Configurable timeouts and connection settings
- Detailed error messages and codes
- Thread-safe configuration
- Comprehensive documentation and examples

[Unreleased]: https://github.com/carrfane/solidgate-ruby-sdk/compare/v0.1.13...HEAD
[0.1.13]: https://github.com/carrfane/solidgate-ruby-sdk/releases/tag/v0.1.13
[0.1.12]: https://github.com/carrfane/solidgate-ruby-sdk/releases/tag/v0.1.12
[0.1.11]: https://github.com/carrfane/solidgate-ruby-sdk/releases/tag/v0.1.11
[0.1.10]: https://github.com/carrfane/solidgate-ruby-sdk/releases/tag/v0.1.10
[0.1.0]: https://github.com/carrfane/solidgate-ruby-sdk/releases/tag/v0.1.0
