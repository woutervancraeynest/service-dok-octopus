# Shared authentication helper for Octopus tools.
#
# Provides convenience methods to extract configuration,
# build an OctopusClient, and handle common auth errors.
#
# Usage in a tool:
#
#   class MyTool
#     extend Tools::OctopusAuth
#
#     def self.call(params:, context:)
#       with_dossier_connection(context) do |client|
#         client.get_relations
#       end
#     end
#   end
#
module Tools
  module OctopusAuth
    REQUIRED_CONFIG_KEYS = %w[octopus_user octopus_password software_house_id].freeze
    MAX_GATEWAY_RETRIES = 2

    # Extract and validate configuration from context.
    # Returns a hash with symbolized keys.
    def extract_config(context)
      config = context["configuration"] || {}

      missing = REQUIRED_CONFIG_KEYS.select { |k| config[k].nil? || config[k].to_s.strip.empty? }
      unless missing.empty?
        raise OctopusClient::ConfigurationError,
          "Missing Octopus configuration: #{missing.join(", ")}. " \
          "Please configure these in your project settings."
      end

      {
        user: config["octopus_user"].to_s.strip,
        password: config["octopus_password"].to_s.strip,
        software_house_id: config["software_house_id"].to_s.strip,
        dossier_id: config["dossier_id"].to_s.strip
      }
    end

    # Build an authenticated OctopusClient.
    # Yields the client and returns the block result.
    # Retries on gateway errors (502, 503, 504) with exponential backoff.
    def with_octopus_client(context)
      config = extract_config(context)
      retries = 0

      begin
        client = OctopusClient::Client.new(
          user: config[:user],
          password: config[:password],
          software_house_id: config[:software_house_id]
        )
        client.authenticate
        yield client
      rescue OctopusClient::AuthenticationError, OctopusClient::ApiError => e
        raise unless gateway_error?(e) && retries < MAX_GATEWAY_RETRIES
        retries += 1
        sleep(retries)
        retry
      end
    rescue OctopusClient::ConfigurationError => e
      { error: e.message }
    rescue OctopusClient::AuthenticationError => e
      { error: "Authentication failed: #{e.message}" }
    rescue OctopusClient::ApiError => e
      { error: "Octopus API error: #{e.message}" }
    rescue Faraday::Error => e
      { error: "Connection error: #{e.message}" }
    end

    # Authenticate + connect to the configured dossier.
    # Yields the client and returns the block result.
    # The dossier_id is taken from context configuration.
    #
    # Retries automatically on gateway errors (502, 503, 504) with
    # exponential backoff (1s, 2s). These are transient server-side
    # issues that typically resolve on retry.
    def with_dossier_connection(context)
      config = extract_config(context)

      if config[:dossier_id].empty?
        return { error: "Missing dossier_id in configuration. Please configure a dossier ID in your project settings." }
      end

      unless config[:dossier_id].match?(/\A\d+\z/)
        return { error: "Invalid dossier_id '#{config[:dossier_id]}': must be a numeric ID. " \
                        "Use the list_dossiers tool to find available dossier IDs." }
      end

      retries = 0

      begin
        client = OctopusClient::Client.new(
          user: config[:user],
          password: config[:password],
          software_house_id: config[:software_house_id]
        )
        client.authenticate
        client.connect_dossier(config[:dossier_id])
        yield client
      rescue OctopusClient::AuthenticationError, OctopusClient::ApiError => e
        raise unless gateway_error?(e) && retries < MAX_GATEWAY_RETRIES
        retries += 1
        sleep(retries)
        retry
      end
    rescue OctopusClient::ConfigurationError => e
      { error: e.message }
    rescue OctopusClient::AuthenticationError => e
      { error: "Authentication failed: #{e.message}" }
    rescue OctopusClient::ApiError => e
      { error: "Octopus API error: #{e.message}" }
    rescue Faraday::Error => e
      { error: "Connection error: #{e.message}" }
    end

    private

    # Check if an error is a gateway error (502, 503, 504) that is
    # worth retrying. These are transient server-side issues.
    def gateway_error?(error)
      error.message =~ /HTTP 50[234]/
    end
  end
end
