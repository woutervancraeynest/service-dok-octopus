# Create a financial or divers booking in the configured Octopus dossier.
#
# Use journal_key starting with "F" for financial journals (e.g. "F1")
# and "D" for divers journals (e.g. "D1").
#
# Each booking line has a type:
#   "A" — Account line (requires account_key)
#   "C" — Client line (requires relation_id or external_relation_id)
#   "S" — Supplier line (requires relation_id or external_relation_id)
#
# Rate limit: 400 calls/day.
#
module Tools
  class CreateFinancialDiversBooking
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id journal_key document_sequence_nr period_nr document_date].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}." }
      end

      unless params["booking_lines"].is_a?(Array) && !params["booking_lines"].empty?
        return { error: "At least one booking_line is required. Each line needs a type ('A', 'C', or 'S') and an amount." }
      end

      booking_data = build_booking_data(params)

      with_dossier_connection(context) do |client|
        client.create_financial_divers_booking(booking_data)
        {
          status: "created",
          message: "Financial/divers booking created successfully in journal #{params["journal_key"]}."
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
      data["bookingLines"] = params["booking_lines"].map { |line| build_booking_line(line) }

      data
    end

    def self.build_booking_line(line)
      result = {
        "type" => line["type"],
        "amount" => line["amount"].to_f
      }

      # Account line
      result["accountKey"] = line["account_key"].to_i if line["account_key"]

      # Client/Supplier line
      result["relationId"] = line["relation_id"].to_i if line["relation_id"]
      result["externalRelationId"] = line["external_relation_id"].to_i if line["external_relation_id"]

      # Optional
      result["reference"] = line["reference"] if line["reference"]
      if line["cost_centre_id"]
        result["costCentreKey"] = { "id" => line["cost_centre_id"].to_i }
      end

      result
    end
  end
end
