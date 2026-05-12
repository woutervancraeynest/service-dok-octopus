# Book invoices in the configured Octopus dossier.
#
# Books through invoices in a journal, making them final and immutable.
# Optionally attaches UBL (Universal Business Language) data.
#
module Tools
  class BookInvoices
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id journal_key].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide bookyear_id and journal_key." }
      end

      with_dossier_connection(context) do |client|
        result = client.book_invoices(
          bookyear_id: params["bookyear_id"].to_i,
          journal_key: params["journal_key"],
          to_document_sequence_nr: params["to_document_sequence_nr"]&.to_i,
          attach_ubl: params["attach_ubl"]
        )

        {
          status: "booked",
          message: "Invoices booked successfully.",
          result: result
        }
      end
    end
  end
end