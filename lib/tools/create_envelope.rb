# Create a payment envelope in the configured Octopus dossier.
#
# Creates a new envelope for grouping payments together for batch processing.
#
module Tools
  class CreateEnvelope
    extend OctopusAuth

    def self.call(params:, context:)
      envelope_data = build_envelope_data(params)

      with_dossier_connection(context) do |client|
        result = client.create_envelope(envelope_data)
        {
          status: "created",
          message: "Envelope created successfully.",
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