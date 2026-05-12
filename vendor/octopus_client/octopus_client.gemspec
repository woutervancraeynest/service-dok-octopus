require_relative "lib/octopus_client/version"

Gem::Specification.new do |spec|
  spec.name          = "octopus_client"
  spec.version       = OctopusClient::VERSION
  spec.authors       = ["by2.be"]
  spec.email         = ["dev@by2.be"]

  spec.summary       = "Ruby client for the Octopus accounting REST API"
  spec.description   = "Handles authentication (2-step token flow), dossier management, " \
                        "and CRUD operations for the Octopus Belgian accounting software API."
  spec.homepage      = "https://github.com/by2-be/octopus_client"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.files         = Dir["lib/**/*", "LICENSE", "*.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-cookie_jar", "~> 0.0.7"
end
