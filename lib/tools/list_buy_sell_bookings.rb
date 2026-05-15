# Get buy or sell bookings from the configured Octopus dossier.
#
# Can filter by bookyear, journal, and document number.
# Returns booking details including relation, amounts, VAT, booking lines, and dates.
#
# Journal key conventions:
#   A = Buy (aankoop), V = Sell (verkoop)
#   e.g. A1 = first buy journal, V1 = first sell journal
#
# Fallback: if the standard endpoint returns HTTP 400 (which happens on some
# dossiers), falls back to the /modified endpoint which is more reliable.
#
module Tools
  class ListBuySellBookings
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        bookings = begin
          client.get_buy_sell_bookings(
            bookyear_key_id: params["bookyear_id"],
            journal_key: params["journal_key"],
            document_sequence_nr: params["document_sequence_nr"]
          )
        rescue OctopusClient::ApiError => e
          raise unless e.message.include?("HTTP 400")

          # Fallback to /modified endpoint
          client.get_modified_buy_sell_bookings(
            bookyear_id: params["bookyear_id"] || -1,
            journal_key: params["journal_key"],
            modified_timestamp: "2000-01-01 00:00:00.000"
          )
        end

        return { bookings: [], total: 0 } if bookings.nil? || bookings.empty?

        result = bookings.is_a?(Array) ? bookings : [bookings]

        # Filter by document_sequence_nr if specified (modified endpoint returns all)
        if params["document_sequence_nr"]
          doc_nr = params["document_sequence_nr"].to_i
          result = result.select { |b| b["documentSequenceNr"] == doc_nr }
        end

        {
          bookings: result,
          total: result.length
        }
      end
    end
  end
end
