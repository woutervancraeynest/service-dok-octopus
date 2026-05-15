# List the chart of accounts for a specific bookyear in the configured Octopus dossier.
#
# Returns account numbers, descriptions (multilingual), VAT settings,
# and cost centre configuration.
#
# Requires a bookyear_id parameter (use get_bookyears to find available IDs).
# Note: This endpoint is limited to 2 calls per day by Octopus.
#
module Tools
  class ListAccounts
    extend OctopusAuth

    def self.call(params:, context:)
      bookyear_id = params["bookyear_id"]
      return { error: "bookyear_id is required. Use get_bookyears to find available bookyear IDs." } unless bookyear_id

      with_dossier_connection(context) do |client|
        accounts = client.get_accounts(bookyear_id: bookyear_id)

        return { accounts: [], total: 0 } if accounts.nil? || accounts.empty?

        {
          accounts: accounts,
          total: accounts.length
        }
      end
    end
  end
end
