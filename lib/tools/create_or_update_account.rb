# Create or update an account in the configured Octopus dossier.
#
# This is an upsert operation: if an account with the given account_key already
# exists in the specified bookyear, it will be updated. Otherwise a new account
# is created.
#
# Rate limit: 400 calls/day.
#
module Tools
  class CreateOrUpdateAccount
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id account_key].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide bookyear_id and account_key." }
      end

      account_data = build_account_data(params)

      with_dossier_connection(context) do |client|
        result = client.create_or_update_account(account_data)
        {
          status: "saved",
          message: "Account saved successfully.",
          account: result
        }
      end
    end

    private

    def self.build_account_data(params)
      data = {
        "bookyearKey" => { "id" => params["bookyear_id"].to_i },
        "accountKey" => params["account_key"].to_i
      }

      data["description1"] = params["description1"] if params["description1"]
      data["description2"] = params["description2"] if params["description2"]
      data["vatCode"] = params["vat_code"] if params["vat_code"]
      data["costCentreRequired"] = params["cost_centre_required"] unless params["cost_centre_required"].nil?
      data["blocked"] = params["blocked"] unless params["blocked"].nil?

      data
    end
  end
end