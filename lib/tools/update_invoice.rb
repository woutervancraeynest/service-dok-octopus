# Update a sell invoice in the configured Octopus dossier.
#
# Updates an existing invoice with new data. Requires the Invoice Module to be
# activated. Uses V-journals (sell journals). For credit notes, both total and
# line amounts must be negative.
#
# Rate limit: 400 calls/day.
#
module Tools
  class UpdateInvoice
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id journal_key document_sequence_nr period_nr document_date expiry_date invoice_lines].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}." }
      end

      if params["invoice_lines"].nil? || params["invoice_lines"].empty?
        return { error: "At least one invoice_line is required." }
      end

      invoice_data = build_invoice_data(params)

      with_dossier_connection(context) do |client|
        result = client.update_invoice(invoice_data)
        {
          status: "updated",
          message: "Invoice updated successfully."
        }
      end
    end

    private

    def self.build_invoice_data(params)
      data = {
        "bookyearKey" => { "id" => params["bookyear_id"].to_i },
        "journalKey" => params["journal_key"],
        "documentSequenceNr" => params["document_sequence_nr"].to_i,
        "bookyearPeriodeNr" => params["period_nr"].to_i,
        "documentDate" => params["document_date"],
        "expiryDate" => params["expiry_date"],
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
      data["relationIdentificationServiceData"] = identification unless identification.empty?

      # Optional fields
      data["reference"] = params["reference"] if params["reference"]
      data["comment"] = params["comment"] if params["comment"]
      data["orderReference"] = params["order_reference"] if params["order_reference"]

      # Invoice lines
      data["invoiceLines"] = params["invoice_lines"].map do |line|
        build_invoice_line(line)
      end

      data
    end

    def self.build_invoice_line(line)
      line_data = {
        "description" => line["description"],
        "count" => line["count"].to_f,
        "unitPrice" => line["unit_price"].to_f,
        "vatCodeKey" => line["vat_code"]
      }

      line_data["unit"] = line["unit"] if line["unit"]
      line_data["bookingAccountNr"] = line["booking_account_nr"].to_i if line["booking_account_nr"]
      line_data["discountPercentage"] = line["discount_percentage"].to_f if line["discount_percentage"]
      line_data["externProductNr"] = line["product_nr"] if line["product_nr"]
      line_data["costCentreKey"] = { "id" => line["cost_centre_id"].to_i } if line["cost_centre_id"]

      line_data
    end
  end
end