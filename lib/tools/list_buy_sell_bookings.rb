# Get buy or sell bookings from the configured Octopus dossier.
#
# Can filter by bookyear, journal, and document number.
# Returns booking details including relation, amounts, VAT, booking lines, and dates.
#
# Journal key conventions:
#   A = Buy (aankoop), V = Sell (verkoop)
#   e.g. A1 = first buy journal, V1 = first sell journal
#
module Tools
  class ListBuySellBookings
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        bookings = client.get_buy_sell_bookings(
          bookyear_key_id: params["bookyear_id"],
          journal_key: params["journal_key"],
          document_sequence_nr: params["document_sequence_nr"]
        )

        return { bookings: [], total: 0 } if bookings.nil? || bookings.empty?

        result = bookings.is_a?(Array) ? bookings : [bookings]

        {
          bookings: result,
          total: result.length
        }
      end
    end
  end
end
