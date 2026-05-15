# Get invoices from the configured Octopus dossier.
#
# Can filter by bookyear, journal, and document number.
# Returns invoice details including relation, lines with products/quantities/prices,
# VAT, and dates.
#
# Note: Requires the Invoice Module to be activated in the Octopus dossier.
#
module Tools
  class ListInvoices
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        invoices = client.get_invoices(
          bookyear_key_id: params["bookyear_id"],
          journal_key: params["journal_key"],
          document_sequence_nr: params["document_sequence_nr"]
        )

        return { invoices: [], total: 0 } if invoices.nil? || invoices.empty?

        result = invoices.is_a?(Array) ? invoices : [invoices]

        {
          invoices: result,
          total: result.length
        }
      end
    end
  end
end
