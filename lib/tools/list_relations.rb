# List all relations (clients and suppliers) in the configured Octopus dossier.
#
# Returns relation details: names, addresses, VAT numbers, bank accounts,
# contact info, and payment terms.
#
# Note: This endpoint is limited to 2 calls per day by Octopus.
#
# Fallback: if the standard endpoint returns HTTP 400, falls back to the
# /modified endpoint which is more reliable on some dossiers.
#
module Tools
  class ListRelations
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        relations = begin
          client.get_relations
        rescue OctopusClient::ApiError => e
          raise unless e.message.include?("HTTP 400")

          # Fallback: /modified returns { modified: [...], deleted: [...] }
          result = client.get_modified_relations(modified_timestamp: "2000-01-01 00:00:00.000")
          result.is_a?(Hash) ? result["modified"] : result
        end

        return { relations: [], total: 0 } if relations.nil? || relations.empty?

        {
          relations: relations,
          total: relations.length
        }
      end
    end
  end
end
