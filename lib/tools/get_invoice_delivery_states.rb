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

      with_dossier_connection(context) do |client|
        result = client.get_invoice_delivery_states(
          bookyear_id: params["bookyear_id"].to_i,
          journal_key: params["journal_key"],
          from_document_sequence_nr: params["from_document_sequence_nr"],
          to_document_sequence_nr: params["to_document_sequence_nr"]
        )

        return { delivery_states: [], total: 0 } if result.nil? || result.empty?

        {
          delivery_states: result,
          total: result.length
        }
      end
    end
  end
end
