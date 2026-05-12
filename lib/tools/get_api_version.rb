# Get the Octopus API version number.
#
# This tool does not require a dossier connection, only authentication.
#
module Tools
  class GetApiVersion
    extend OctopusAuth

    def self.call(params:, context:)
      with_octopus_client(context) do |client|
        result = client.get_api_version

        {
          version: result
        }
      end
    end
  end
end