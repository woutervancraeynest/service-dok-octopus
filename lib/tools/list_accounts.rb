# List the chart of accounts for a specific bookyear in the configured Octopus dossier.
#
# Returns account numbers, descriptions (multilingual), VAT settings,
# and cost centre configuration.
#
# Requires a bookyear_id parameter (use get_bookyears to find available IDs).
# Note: This endpoint is limited to 2 calls per day by Octopus.
#
# Fallback: if the standard endpoint returns HTTP 400, falls back to the
# /modified endpoint which is more reliable on some dossiers.
#
module Tools
  class ListAccounts
    extend OctopusAuth

    def self.call(params:, context:)
      bookyear_id = params["bookyear_id"]
      return { error: "bookyear_id is required. Use get_bookyears to find available bookyear IDs." } unless bookyear_id

      with_dossier_connection(context) do |client|
        accounts = begin
          client.get_accounts(bookyear_id: bookyear_id)
        rescue OctopusClient::ApiError => e
          raise unless e.message.include?("HTTP 400")

          # Fallback: /modified returns { modified: [...], deleted: [...] }
          result = client.get_modified_accounts(modified_timestamp: "2000-01-01 00:00:00.000")
          result.is_a?(Hash) ? result["modified"] : result
        end

        return { accounts: [], total: 0 } if accounts.nil? || accounts.empty?

        {
          accounts: accounts,
          total: accounts.length
        }
      end
    end
  end
end
