# Get invoice delivery states from the configured Octopus dossier.
#
# Returns delivery status information for invoices within the specified range.
#
module Tools
  class GetInvoiceDeliveryStates
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide a bookyear_id." }
      end

      selection_data = build_selection_data(params)

      with_dossier_connection(context) do |client|
        result = client.get_invoice_delivery_states(selection_data)

        return { delivery_states: [], total: 0 } if result.nil? || result.empty?

        {
          delivery_states: result,
          total: result.length
        }
      end
    end

    private

    def self.build_selection_data(params)
      data = {
        "bookyearKey" => { "id" => params["bookyear_id"].to_i }
      }

      data["journalKey"] = params["journal_key"] if params["journal_key"]
      data["fromDocumentSequenceNr"] = params["from_document_sequence_nr"].to_i if params["from_document_sequence_nr"]
      data["toDocumentSequenceNr"] = params["to_document_sequence_nr"].to_i if params["to_document_sequence_nr"]

      data
    end
  end
end