# Get all active (not closed) cost centres from the configured Octopus dossier.
#
# Returns cost centre details including IDs, descriptions, and status.
#
module Tools
  class GetActiveCostCentres
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        result = client.get_active_cost_centres

        return { cost_centres: [], total: 0 } if result.nil? || result.empty?

        {
          cost_centres: result,
          total: result.length
        }
      end
    end
  end
end