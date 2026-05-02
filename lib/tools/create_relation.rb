# Create or update a relation (client/supplier) in the configured Octopus dossier.
#
# This is an upsert operation: if a relation with the given relation_id or
# external_relation_id already exists, it will be updated. Otherwise a new
# relation is created.
#
# Rate limit: 400 calls/day.
#
module Tools
  class CreateRelation
    extend OctopusAuth

    REQUIRED_PARAMS = %w[name].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide at least a name for the relation." }
      end

      relation_data = build_relation_data(params)

      with_dossier_connection(context) do |client|
        result = client.create_or_update_relation(relation_data)
        {
          status: result[:status],
          message: result[:status] == "created" ? "Relation created successfully." : "Relation updated successfully.",
          relation: result[:relation]
        }
      end
    end

    private

    def self.build_relation_data(params)
      data = {
        "currencyCode" => params["currency_code"] || "EUR"
      }

      # Relation identification (for upsert matching)
      identification = {}
      if params["relation_id"]
        identification["relationKey"] = { "id" => params["relation_id"].to_i }
      end
      if params["external_relation_id"]
        identification["externalRelationId"] = params["external_relation_id"].to_i
      end
      data["relationIdentificationServiceData"] = identification

      # Basic info
      data["name"] = params["name"] if params["name"]
      data["firstName"] = params["first_name"] if params["first_name"]
      data["client"] = params["client"] unless params["client"].nil?
      data["supplier"] = params["supplier"] unless params["supplier"].nil?
      data["vatNr"] = params["vat_number"] if params["vat_number"]
      data["email"] = params["email"] if params["email"]
      data["telephone"] = params["telephone"] if params["telephone"]
      data["mobile"] = params["mobile"] if params["mobile"]

      # Address
      data["streetAndNr"] = params["street_and_nr"] if params["street_and_nr"]
      data["postalCode"] = params["postal_code"] if params["postal_code"]
      data["city"] = params["city"] if params["city"]
      data["country"] = params["country"] || "BE"

      # Bank
      data["ibanAccountNr"] = params["iban"] if params["iban"]
      data["bicCode"] = params["bic"] if params["bic"]

      # Payment terms
      if params["payment_days"]
        data["expirationDays"] = params["payment_days"].to_i
        data["expirationType"] = params["expiration_type"]&.to_i || 2 # default: after invoice date
      end

      data
    end
  end
end
