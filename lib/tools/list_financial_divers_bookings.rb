# Get financial or divers bookings from the configured Octopus dossier.
#
# Can filter by bookyear, journal, and document number. Returns booking details
# including amounts, dates, and booking lines.
#
module Tools
  class ListFinancialDiversBookings
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        result = client.get_financial_divers_bookings(
          bookyear_key_id: params["bookyear_id"],
          journal_key: params["journal_key"],
          document_sequence_nr: params["document_sequence_nr"]
        )

        return { bookings: [], total: 0 } if result.nil? || result.empty?

        {
          bookings: result,
          total: result.length
        }
      end
    end
  end
end