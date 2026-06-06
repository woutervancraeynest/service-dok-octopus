# Update a financial or divers booking in the configured Octopus dossier.
#
# Updates an existing booking with new data. Use journal_key 'F1' for financial
# journals, 'D1' for divers. Each booking line must specify a type: 'A' for
# account line, 'C' for client line, 'S' for supplier line.
#
# Rate limit: 400 calls/day.
#
module Tools
  class UpdateFinancialDiversBooking
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id journal_key document_sequence_nr period_nr document_date booking_lines].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}." }
      end

      if params["booking_lines"].nil? || params["booking_lines"].empty?
        return { error: "At least one booking_line is required." }
      end

      booking_data = build_booking_data(params)

      with_dossier_connection(context) do |client|
        result = client.update_financial_divers_booking(booking_data)
        {
          status: "updated",
          message: "Financial/divers booking updated successfully."
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
        "exchangeRate" => params["exchange_rate"]&.to_f || 1.0
      }

      # Booking lines
      data["bookingLines"] = params["booking_lines"].map do |line|
        build_booking_line(line)
      end

      data
    end

    def self.build_booking_line(line)
      line_data = {
        "type" => line["type"],
        "amount" => line["amount"].to_f
      }

      case line["type"]
      when "A"
        line_data["accountKey"] = line["account_key"].to_i
      when "C", "S"
        # Per FinancialDiversBookingLineServiceData: relationId is an int,
        # NOT a {id: ...} wrapper object (unlike many other schemas).
        line_data["relationId"] = line["relation_id"].to_i if line["relation_id"]
        line_data["externalRelationId"] = line["external_relation_id"].to_i if line["external_relation_id"]
      end

      line_data["reference"] = line["reference"] if line["reference"]
      line_data["costCentreKey"] = { "id" => line["cost_centre_id"].to_i } if line["cost_centre_id"]

      line_data
    end
  end
end