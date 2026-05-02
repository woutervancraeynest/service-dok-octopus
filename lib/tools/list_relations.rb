# List all relations (clients and suppliers) in the configured Octopus dossier.
#
# Returns relation details: names, addresses, VAT numbers, bank accounts,
# contact info, and payment terms.
#
# Note: This endpoint is limited to 2 calls per day by Octopus.
#
module Tools
  class ListRelations
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        relations = client.get_relations

        return { relations: [], total: 0 } if relations.nil? || relations.empty?

        {
          relations: relations,
          total: relations.length
        }
      end
    end
  end
end
