# Insert a balancing entry in the configured Octopus dossier.
#
# Creates a balancing entry to match payments with invoices or other documents.
#
# Rate limit: 400 calls/day.
#
module Tools
  class InsertBalancing
    extend OctopusAuth

    def self.call(params:, context:)
      balancing_data = build_balancing_data(params)

      with_dossier_connection(context) do |client|
        result = client.insert_balancing(balancing_data)
        {
          status: "created",
          message: "Balancing inserted successfully."
        }
      end
    end

    private

    def self.build_balancing_data(params)
      data = {}

      # Build balancing data based on the provided parameters
      # The exact structure depends on the balancing type and requirements
      data["amount"] = params["amount"].to_f if params["amount"]
      data["reference"] = params["reference"] if params["reference"]
      data["balancingDate"] = params["balancing_date"] if params["balancing_date"]

      # Document references for balancing
      if params["document_keys"]
        data["documentKeys"] = params["document_keys"].map do |doc|
          {
            "bookyearKey" => { "id" => doc["bookyear_id"].to_i },
            "journalKey" => doc["journal_key"],
            "documentSequenceNr" => doc["document_sequence_nr"].to_i
          }
        end
      end

      data
    end
  end
end