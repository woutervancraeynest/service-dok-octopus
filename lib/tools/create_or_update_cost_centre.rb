# Create or update a cost centre in the configured Octopus dossier.
#
# This is an upsert operation: if a cost centre with the given ID already exists,
# it will be updated. Otherwise a new cost centre is created.
#
# Rate limit: 400 calls/day.
#
module Tools
  class CreateOrUpdateCostCentre
    extend OctopusAuth

    REQUIRED_PARAMS = %w[description].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide a description." }
      end

      cost_centre_data = build_cost_centre_data(params)

      with_dossier_connection(context) do |client|
        result = client.create_or_update_cost_centre(cost_centre_data)
        {
          status: "saved",
          message: "Cost centre saved successfully.",
          cost_centre: result
        }
      end
    end

    private

    def self.build_cost_centre_data(params)
      data = {
        "description" => params["description"]
      }

      # For updates, include the cost centre key
      if params["cost_centre_id"]
        data["costCentreKey"] = { "id" => params["cost_centre_id"].to_i }
      end

      data["closed"] = params["closed"] unless params["closed"].nil?

      data
    end
  end
end