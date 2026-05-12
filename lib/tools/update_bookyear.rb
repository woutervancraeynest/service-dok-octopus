# Update an existing bookyear in the configured Octopus dossier.
#
# Updates bookyear settings such as description, dates, and status.
#
module Tools
  class UpdateBookyear
    extend OctopusAuth

    def self.call(params:, context:)
      bookyear_data = build_bookyear_data(params)

      with_dossier_connection(context) do |client|
        result = client.update_bookyear(bookyear_data)
        {
          status: "updated",
          message: "Bookyear updated successfully."
        }
      end
    end

    private

    def self.build_bookyear_data(params)
      data = {}

      data["bookyearKey"] = { "id" => params["bookyear_id"].to_i } if params["bookyear_id"]
      data["description"] = params["description"] if params["description"]
      data["startDate"] = params["start_date"] if params["start_date"]
      data["endDate"] = params["end_date"] if params["end_date"]
      data["numberOfPeriods"] = params["number_of_periods"].to_i if params["number_of_periods"]
      data["currencyCode"] = params["currency_code"] if params["currency_code"]
      data["closed"] = params["closed"] unless params["closed"].nil?

      data
    end
  end
end