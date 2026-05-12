# Get all payment envelopes from the configured Octopus dossier.
#
# Returns envelope details including IDs, descriptions, and status.
#
module Tools
  class GetEnvelopes
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        result = client.get_envelopes

        return { envelopes: [], total: 0 } if result.nil? || result.empty?

        {
          envelopes: result,
          total: result.length
        }
      end
    end
  end
end