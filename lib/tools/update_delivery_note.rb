# Update a delivery note in the configured Octopus dossier.
#
# Updates an existing delivery note with new data. Similar structure to
# invoices but for delivery tracking purposes.
#
# Rate limit: 400 calls/day.
#
module Tools
  class UpdateDeliveryNote
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id journal_key document_sequence_nr period_nr document_date expiry_date delivery_lines].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}." }
      end

      if params["delivery_lines"].nil? || params["delivery_lines"].empty?
        return { error: "At least one delivery_line is required." }
      end

      delivery_note_data = build_delivery_note_data(params)

      with_dossier_connection(context) do |client|
        result = client.update_delivery_note(delivery_note_data)
        {
          status: "updated",
          message: "Delivery note updated successfully."
        }
      end
    end

    private

    def self.build_delivery_note_data(params)
      data = {
        "bookyearKey" => { "id" => params["bookyear_id"].to_i },
        "journalKey" => params["journal_key"],
        "documentSequenceNr" => params["document_sequence_nr"].to_i,
        "periodNr" => params["period_nr"].to_i,
        "documentDate" => params["document_date"],
        "expiryDate" => params["expiry_date"],
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

      # Delivery lines
      data["deliveryLines"] = params["delivery_lines"].map do |line|
        build_delivery_line(line)
      end

      data
    end

    def self.build_delivery_line(line)
      line_data = {
        "description" => line["description"],
        "count" => line["count"].to_f,
        "unitPrice" => line["unit_price"].to_f,
        "vatCode" => line["vat_code"]
      }

      line_data["unit"] = line["unit"] if line["unit"]
      line_data["bookingAccountNr"] = line["booking_account_nr"].to_i if line["booking_account_nr"]
      line_data["discountPercentage"] = line["discount_percentage"].to_f if line["discount_percentage"]
      line_data["productNr"] = line["product_nr"] if line["product_nr"]
      line_data["costCentreKey"] = { "id" => line["cost_centre_id"].to_i } if line["cost_centre_id"]

      line_data
    end
  end
end