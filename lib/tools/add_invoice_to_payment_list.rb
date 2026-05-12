# Add an invoice to the payment list in the configured Octopus dossier.
#
# Adds an existing invoice to the payment list for batch processing.
#
module Tools
  class AddInvoiceToPaymentList
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id journal_key document_sequence_nr].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide bookyear_id, journal_key, and document_sequence_nr." }
      end

      document_data = build_document_data(params)

      with_dossier_connection(context) do |client|
        result = client.add_invoice_to_payment_list(
          document_data,
          amount: params["amount"]&.to_f,
          reference: params["reference"],
          iban: params["iban"],
          bic: params["bic"]
        )

        {
          status: "added",
          message: "Invoice added to payment list successfully.",
          result: result
        }
      end
    end

    private

    def self.build_document_data(params)
      {
        "bookyearKey" => { "id" => params["bookyear_id"].to_i },
        "journalKey" => params["journal_key"],
        "documentSequenceNr" => params["document_sequence_nr"].to_i
      }
    end
  end
end