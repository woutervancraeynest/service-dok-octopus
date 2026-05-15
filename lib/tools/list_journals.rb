# List all journals for a specific bookyear in the configured Octopus dossier.
#
# Returns journal keys (e.g. A1=Buy, V1=Sell, F1=Financial, D1=Divers),
# names, currency, closed status, and last booked document number.
#
# Requires a bookyear_id parameter (use get_bookyears to find available IDs).
#
# Fallback: if the standard endpoint returns HTTP 400, falls back to the
# /modified endpoint which is more reliable on some dossiers.
#
module Tools
  class ListJournals
    extend OctopusAuth

    def self.call(params:, context:)
      bookyear_id = params["bookyear_id"]
      return { error: "bookyear_id is required. Use get_bookyears to find available bookyear IDs." } unless bookyear_id

      with_dossier_connection(context) do |client|
        journals = begin
          client.get_journals(bookyear_id: bookyear_id)
        rescue OctopusClient::ApiError => e
          raise unless e.message.include?("HTTP 400")

          # Fallback to /modified endpoint
          client.get_modified_journals(modified_timestamp: "2000-01-01 00:00:00.000")
        end

        return { journals: [], total: 0 } if journals.nil? || journals.empty?

        result = journals.is_a?(Array) ? journals : [journals]

        {
          journals: result,
          total: result.length
        }
      end
    end
  end
end
