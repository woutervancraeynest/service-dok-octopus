# Delete a balancing entry in the configured Octopus dossier.
#
# Removes a previously created balancing (payment-to-invoice match).
# Use this to undo an incorrect reconciliation.
#
# Supports three modes:
#   - By balancing item: provide balancing_item data
#   - By booking line: provide booking line key to remove all balancings for that line
#   - By document: provide document key to remove all balancings for that document
#
module Tools
  class DeleteBalancing
    extend OctopusAuth

    VALID_MODES = %w[item bookingline document].freeze

    def self.call(params:, context:)
      mode = params["mode"] || "item"

      unless VALID_MODES.include?(mode)
        return { error: "Invalid mode: #{mode}. Use 'item', 'bookingline', or 'document'." }
      end

      with_dossier_connection(context) do |client|
        case mode
        when "item"
          data = build_item_data(params)
          client.delete_balancing(data)
        when "bookingline"
          data = build_bookingline_data(params)
          client.delete_balancing_by_bookingline(data)
        when "document"
          data = build_document_data(params)
          client.delete_balancing_by_document(data)
        end

        {
          status: "deleted",
          message: "Balancing deleted successfully (mode: #{mode})."
        }
      end
    end

    private

    def self.build_item_data(params)
      data = {}
      data["amount"] = params["amount"].to_f if params["amount"]
      data["reference"] = params["reference"] if params["reference"]
      data["balancingDate"] = params["balancing_date"] if params["balancing_date"]

      if params["document_keys"]
        data["documentKeys"] = params["document_keys"].map do |doc|
          {
            "bookyearKey" => { "id" => doc["bookyear_id"].to_i },
            "journalKey" => doc["journal_key"],
            "documentSequenceNr" => doc["document_sequence_nr"].to_i
          }
        end
      end

      data
    end

    def self.build_bookingline_data(params)
      {
        "bookyearKey" => { "id" => params["bookyear_id"].to_i },
        "journalKey" => params["journal_key"],
        "documentSequenceNr" => params["document_sequence_nr"].to_i,
        "bookingLineSequenceNr" => params["booking_line_sequence_nr"].to_i
      }
    end

    def self.build_document_data(params)
      {
        "bookyearKey" => { "id" => params["bookyear_id"].to_i },
        "journalKey" => params["journal_key"],
        "documentSequenceNr" => params["document_sequence_nr"].to_i
      }
    end
  end
end
