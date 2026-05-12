# Update a buy or sell booking in the configured Octopus dossier.
#
# Updates an existing booking with new data. Use journal_key 'A1' for buy bookings,
# 'V1' for sell bookings. For credit notes, set amount to negative (but keep line
# amounts positive).
#
# Rate limit: 400 calls/day.
#
module Tools
  class UpdateBuySellBooking
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id journal_key document_sequence_nr period_nr document_date expiry_date amount].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}." }
      end

      booking_data = build_booking_data(params)

      with_dossier_connection(context) do |client|
        result = client.update_buy_sell_booking(booking_data)
        {
          status: "updated",
          message: "Buy/sell booking updated successfully."
        }
      end
    end

    private

    def self.build_booking_data(params)
      data = {
        "bookyearKey" => { "id" => params["bookyear_id"].to_i },
        "journalKey" => params["journal_key"],
        "documentSequenceNr" => params["document_sequence_nr"].to_i,
        "periodNr" => params["period_nr"].to_i,
        "documentDate" => params["document_date"],
        "expiryDate" => params["expiry_date"],
        "amount" => params["amount"].to_f,
        "currencyCode" => params["currency_code"] || "EUR"
      }

      # Relation identification
      if params["relation_id"]
        data["relationKey"] = { "id" => params["relation_id"].to_i }
      elsif params["external_relation_id"]
        data["externalRelationId"] = params["external_relation_id"].to_i
      end

      # Optional fields
      data["reference"] = params["reference"] if params["reference"]
      data["comment"] = params["comment"] if params["comment"]
      data["orderReference"] = params["order_reference"] if params["order_reference"]

      # Booking lines
      if params["booking_lines"]
        data["bookingLines"] = params["booking_lines"].map do |line|
          build_booking_line(line)
        end
      end

      { "buySellBookingServiceData" => data }
    end

    def self.build_booking_line(line)
      line_data = {
        "accountKey" => line["account_key"].to_i,
        "baseAmount" => line["base_amount"].to_f,
        "vatCode" => line["vat_code"],
        "vatAmount" => line["vat_amount"].to_f
      }

      line_data["comment"] = line["comment"] if line["comment"]
      line_data["costCentreKey"] = { "id" => line["cost_centre_id"].to_i } if line["cost_centre_id"]

      line_data
    end
  end
end