# Create a buy or sell booking in the configured Octopus dossier.
#
# Use journal_key starting with "A" for buy bookings (e.g. "A1")
# and "V" for sell bookings (e.g. "V1").
#
# For credit notes: set amount to a negative value. Individual line
# amounts that contribute to the credit note should remain positive.
#
# Rate limit: 400 calls/day.
#
module Tools
  class CreateBuySellBooking
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id journal_key document_sequence_nr period_nr document_date expiry_date amount].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}." }
      end

      unless params["relation_id"] || params["external_relation_id"]
        return { error: "Either relation_id or external_relation_id is required to identify the client/supplier." }
      end

      booking_data = build_booking_data(params)

      with_dossier_connection(context) do |client|
        client.create_buy_sell_booking(booking_data)
        {
          status: "created",
          message: "Buy/sell booking created successfully in journal #{params["journal_key"]}."
        }
      end
    end

    private

    def self.build_booking_data(params)
      data = {
        "bookyearKey" => { "id" => params["bookyear_id"].to_i },
        "journalKey" => params["journal_key"],
        "documentSequenceNr" => params["document_sequence_nr"].to_i,
        "bookyearPeriodeNr" => params["period_nr"].to_i,
        "documentDate" => params["document_date"],
        "expiryDate" => params["expiry_date"],
        "amount" => params["amount"].to_f,
        "currencyCode" => params["currency_code"] || "EUR",
        "exchangeRate" => params["exchange_rate"]&.to_f || 1.0
      }

      # Relation identification
      identification = {}
      if params["relation_id"]
        identification["relationKey"] = { "id" => params["relation_id"].to_i }
      end
      if params["external_relation_id"]
        identification["externalRelationId"] = params["external_relation_id"].to_i
      end
      data["relationIdentificationServiceData"] = identification

      # Optional fields
      data["reference"] = params["reference"] if params["reference"]
      data["comment"] = params["comment"] if params["comment"]
      data["orderReference"] = params["order_reference"] if params["order_reference"]

      # Booking lines
      if params["booking_lines"].is_a?(Array) && !params["booking_lines"].empty?
        data["bookingLines"] = params["booking_lines"].map { |line| build_booking_line(line) }
      end

      data
    end

    def self.build_booking_line(line)
      result = {}
      result["accountKey"] = line["account_key"].to_i if line["account_key"]
      result["baseAmount"] = line["base_amount"].to_f if line["base_amount"]
      result["vatCodeKey"] = line["vat_code"] if line["vat_code"]
      result["vatAmount"] = line["vat_amount"].to_f if line["vat_amount"]
      result["comment"] = line["comment"] if line["comment"]
      if line["cost_centre_id"]
        result["costCentreKey"] = { "id" => line["cost_centre_id"].to_i }
      end
      result
    end
  end
end
