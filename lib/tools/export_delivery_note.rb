# Export a delivery note as PDF from the configured Octopus dossier.
#
# Returns the delivery note data including PDF content if requested.
#
module Tools
  class ExportDeliveryNote
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id journal_key document_sequence_nr].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide bookyear_id, journal_key, and document_sequence_nr." }
      end

      with_dossier_connection(context) do |client|
        result = client.export_delivery_note(
          bookyear_id: params["bookyear_id"].to_i,
          journal_key: params["journal_key"],
          document_sequence_nr: params["document_sequence_nr"].to_i,
          return_delivery_note: true,
          return_pdf_document: params["return_pdf"] || false
        )

        {
          delivery_note: result
        }
      end
    end
  end
end