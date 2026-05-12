require_relative "octopus_client/version"
require_relative "octopus_client/errors"
require_relative "octopus_client/client"

module OctopusClient
  # Convenience constant for backward compatibility.
  BASE_URL = Client::DEFAULT_BASE_URL
end
