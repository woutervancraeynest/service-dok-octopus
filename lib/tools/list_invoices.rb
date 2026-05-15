# Get invoices from the configured Octopus dossier.
#
# Can filter by bookyear, journal, and document number.
# Returns invoice details including relation, lines with products/quantities/prices,
# VAT, and dates.
#
# Note: Requires the Invoice Module to be activated in the Octopus dossier.
#
# Fallback: if the standard endpoint returns HTTP 400 (which happens when the
# invoice module is not activated or on some dossiers), falls back to the
# /modified endpoint.
#
module Tools
  class ListInvoices
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        invoices = begin
          client.get_invoices(
            bookyear_key_id: params["bookyear_id"],
            journal_key: params["journal_key"],
            document_sequence_nr: params["document_sequence_nr"]
          )
        rescue OctopusClient::ApiError => e
          raise unless e.message.include?("HTTP 400")

          # Fallback to /modified endpoint
          client.get_modified_invoices(
            bookyear_id: params["bookyear_id"] || -1,
            journal_key: params["journal_key"],
            modified_timestamp: "2000-01-01 00:00:00.000"
          )
        end

        return { invoices: [], total: 0 } if invoices.nil? || invoices.empty?

        result = invoices.is_a?(Array) ? invoices : [invoices]

        # Filter by document_sequence_nr if specified (modified endpoint returns all)
        if params["document_sequence_nr"]
          doc_nr = params["document_sequence_nr"].to_i
          result = result.select { |inv| inv["documentSequenceNr"] == doc_nr }
        end

        {
          invoices: result,
          total: result.length
        }
      end
    end
  end
end
