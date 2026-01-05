# frozen_string_literal: true

require_relative "lib/solidgate/version"

Gem::Specification.new do |spec|
  spec.name = "solidgate-ruby-sdk"
  spec.version = Solidgate::VERSION
  spec.authors = ["Hector Carrillo"]
  spec.email = ["carrfane@gmail.com"]
  
  spec.summary = "Ruby SDK for Solidgate payment processing"
  spec.description = "A Ruby SDK for integrating with the Solidgate payment gateway API"
  spec.homepage = "https://github.com/carrfane/solidgate-ruby-sdk"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"
  
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/carrfane/solidgate-ruby-sdk"
  spec.metadata["changelog_uri"] = "https://github.com/carrfane/solidgate-ruby-sdk/blob/master/CHANGELOG.md"
  
  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  
  # Runtime dependencies
  spec.add_dependency "faraday"
  spec.add_dependency "faraday-multipart"
  
  # Development dependencies
  # spec.add_development_dependency "rspec", "~> 3.0"
  # spec.add_development_dependency "webmock", "~> 3.0"
  # spec.add_development_dependency "vcr", "~> 6.0"
  # spec.add_development_dependency "rubocop", "~> 1.0"
  # spec.add_development_dependency "pry", "~> 0.14"
end
