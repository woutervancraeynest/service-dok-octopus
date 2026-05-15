# Get modified balancings from the configured Octopus dossier.
#
# Returns balancings that were created or modified since the specified timestamp.
# Useful for verifying that reconciliation entries were recorded correctly,
# or for auditing recent balancing activity.
#
module Tools
  class GetModifiedBalancings
    extend OctopusAuth

    def self.call(params:, context:)
      modified_timestamp = params["modified_timestamp"] || "2000-01-01 00:00:00.000"

      with_dossier_connection(context) do |client|
        result = client.get_modified_balancings(modified_timestamp: modified_timestamp)

        return { balancings: [], total: 0 } if result.nil? || result.empty?

        balancings = result.is_a?(Array) ? result : [result]

        {
          balancings: balancings,
          total: balancings.length
        }
      end
    end
  end
end
