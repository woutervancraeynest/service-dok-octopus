# Update a payment envelope in the configured Octopus dossier.
#
# Updates an existing envelope with new information.
#
module Tools
  class UpdateEnvelope
    extend OctopusAuth

    REQUIRED_PARAMS = %w[envelope_key_id].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide an envelope_key_id." }
      end

      envelope_data = build_envelope_data(params)

      with_dossier_connection(context) do |client|
        result = client.update_envelope(
          envelope_key_id: params["envelope_key_id"].to_i,
          envelope_data: envelope_data
        )
        {
          status: "updated",
          message: "Envelope updated successfully.",
          envelope: result
        }
      end
    end

    private

    def self.build_envelope_data(params)
      data = {}

      data["description"] = params["description"] if params["description"]
      data["executionDate"] = params["execution_date"] if params["execution_date"]
      data["reference"] = params["reference"] if params["reference"]
      data["debitAccountIban"] = params["debit_account_iban"] if params["debit_account_iban"]
      data["debitAccountBic"] = params["debit_account_bic"] if params["debit_account_bic"]

      data
    end
  end
end