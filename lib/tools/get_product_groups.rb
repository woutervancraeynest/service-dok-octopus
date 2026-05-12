# Get all product groups from the configured Octopus dossier.
#
# Returns product group details including IDs and descriptions.
#
module Tools
  class GetProductGroups
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        result = client.get_productgroups

        return { product_groups: [], total: 0 } if result.nil? || result.empty?

        {
          product_groups: result,
          total: result.length
        }
      end
    end
  end
end