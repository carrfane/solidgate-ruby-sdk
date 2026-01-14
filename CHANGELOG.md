# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/carrfane/solidgate-ruby-sdk/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/carrfane/solidgate-ruby-sdk/releases/tag/v0.1.0
