# Insert a balancing entry in the configured Octopus dossier.
#
# Creates a balancing entry to match payments with invoices or other documents.
# Requires document_keys (at least 2 documents to match) and an amount.
#
# Rate limit: 400 calls/day.
#
module Tools
  class InsertBalancing
    extend OctopusAuth

    def self.call(params:, context:)
      # Validate required params
      unless params["document_keys"].is_a?(Array) && params["document_keys"].length >= 2
        return { error: "document_keys is required and must contain at least 2 documents " \
                        "(e.g. one bank booking and one invoice). Each document needs " \
                        "bookyear_id, journal_key, and document_sequence_nr." }
      end

      unless params["amount"]
        return { error: "amount is required. Provide the balancing amount." }
      end

      # Validate each document key
      params["document_keys"].each_with_index do |doc, i|
        missing = %w[bookyear_id journal_key document_sequence_nr].select { |k| doc[k].nil? }
        unless missing.empty?
          return { error: "document_keys[#{i}] is missing: #{missing.join(", ")}." }
        end
      end

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
      data = {
        "amount" => params["amount"].to_f
      }

      data["reference"] = params["reference"] if params["reference"]
      data["balancingDate"] = params["balancing_date"] if params["balancing_date"]

      data["documentKeys"] = params["document_keys"].map do |doc|
        {
          "bookyearKey" => { "id" => doc["bookyear_id"].to_i },
          "journalKey" => doc["journal_key"],
          "documentSequenceNr" => doc["document_sequence_nr"].to_i
        }
      end

      data
    end
  end
end
