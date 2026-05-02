# Create a sell invoice in the configured Octopus dossier.
#
# Requires the Invoice Module to be activated in the Octopus dossier.
# Uses V-journals (sell journals) for invoice creation.
#
# For credit notes: both total amount and line amounts must be negative.
#
# Rate limit: 400 calls/day.
#
module Tools
  class CreateInvoice
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id journal_key document_sequence_nr period_nr document_date expiry_date].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}." }
      end

      unless params["relation_id"] || params["external_relation_id"]
        return { error: "Either relation_id or external_relation_id is required to identify the customer." }
      end

      unless params["invoice_lines"].is_a?(Array) && !params["invoice_lines"].empty?
        return { error: "At least one invoice_line is required." }
      end

      invoice_data = build_invoice_data(params)

      with_dossier_connection(context) do |client|
        client.create_invoice(invoice_data)
        {
          status: "created",
          message: "Invoice created successfully in journal #{params["journal_key"]}."
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
      data["relationIdentificationServiceData"] = identification

      # Optional fields
      data["reference"] = params["reference"] if params["reference"]
      data["comment"] = params["comment"] if params["comment"]
      data["orderReference"] = params["order_reference"] if params["order_reference"]

      # Invoice lines
      data["invoiceLines"] = params["invoice_lines"].map { |line| build_invoice_line(line) }

      data
    end

    def self.build_invoice_line(line)
      result = {}
      result["description"] = line["description"] if line["description"]
      result["count"] = line["count"].to_f if line["count"]
      result["unitPrice"] = line["unit_price"].to_f if line["unit_price"]
      result["unit"] = line["unit"] if line["unit"]
      result["vatCodeKey"] = line["vat_code"] if line["vat_code"]
      result["bookingAccountNr"] = line["booking_account_nr"].to_i if line["booking_account_nr"]
      result["discountPercentage"] = line["discount_percentage"].to_f if line["discount_percentage"]
      result["externProductNr"] = line["product_nr"] if line["product_nr"]
      if line["cost_centre_id"]
        result["costCentreKey"] = { "id" => line["cost_centre_id"].to_i }
      end
      result
    end
  end
end
