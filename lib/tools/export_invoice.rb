# Export an invoice as PDF or eInvoice XML from the configured Octopus dossier.
#
# Returns the invoice data including PDF content if requested.
#
module Tools
  class ExportInvoice
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id journal_key document_sequence_nr].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide bookyear_id, journal_key, and document_sequence_nr." }
      end

      with_dossier_connection(context) do |client|
        result = client.export_invoice(
          bookyear_id: params["bookyear_id"].to_i,
          journal_key: params["journal_key"],
          document_sequence_nr: params["document_sequence_nr"].to_i,
          return_invoice: true,
          return_pdf_document: params["return_pdf"] || false
        )

        {
          invoice: result
        }
      end
    end
  end
end