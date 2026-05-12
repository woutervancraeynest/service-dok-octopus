# Generate a delivery note PDF from the configured Octopus dossier.
#
# Generates a server-side PDF for an existing delivery note and optionally
# publishes it to the DMS (Document Management System).
#
module Tools
  class GenerateDeliveryNote
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id journal_key document_sequence_nr].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide bookyear_id, journal_key, and document_sequence_nr." }
      end

      with_dossier_connection(context) do |client|
        result = client.generate_delivery_note(
          bookyear_id: params["bookyear_id"].to_i,
          journal_key: params["journal_key"],
          document_sequence_nr: params["document_sequence_nr"].to_i,
          return_delivery_note: params["return_delivery_note"] || true,
          publish_pdf_in_dms: params["publish_pdf_in_dms"] || false,
          return_pdf_document: params["return_pdf_document"] || false
        )

        {
          delivery_note: result
        }
      end
    end
  end
end