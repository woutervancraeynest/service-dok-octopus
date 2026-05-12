# Create or update a product in the configured Octopus dossier.
#
# This is an upsert operation: if a product with the given ID already exists,
# it will be updated. Otherwise a new product is created.
#
# Rate limit: 400 calls/day.
#
module Tools
  class CreateOrUpdateProduct
    extend OctopusAuth

    REQUIRED_PARAMS = %w[description].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide a description." }
      end

      product_data = build_product_data(params)

      with_dossier_connection(context) do |client|
        result = client.create_or_update_product(product_data)
        {
          status: "saved",
          message: "Product saved successfully.",
          product: result
        }
      end
    end

    private

    def self.build_product_data(params)
      data = {
        "description" => params["description"]
      }

      # For updates, include the product key
      if params["product_id"]
        data["productKey"] = { "id" => params["product_id"].to_i }
      end

      data["externalProductNr"] = params["external_product_nr"] if params["external_product_nr"]
      data["unitPrice"] = params["unit_price"].to_f if params["unit_price"]
      data["unit"] = params["unit"] if params["unit"]
      data["vatCode"] = params["vat_code"] if params["vat_code"]
      data["bookingAccountNr"] = params["booking_account_nr"].to_i if params["booking_account_nr"]
      data["productGroupKey"] = { "id" => params["product_group_id"].to_i } if params["product_group_id"]
      data["blocked"] = params["blocked"] unless params["blocked"].nil?

      data
    end
  end
end