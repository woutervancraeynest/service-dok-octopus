# Create a new bookyear in the configured Octopus dossier.
#
# Creates a new accounting year with the specified settings and periods.
#
module Tools
  class CreateBookyear
    extend OctopusAuth

    def self.call(params:, context:)
      bookyear_data = build_bookyear_data(params)

      with_dossier_connection(context) do |client|
        result = client.create_bookyear(bookyear_data)
        {
          status: "created",
          message: "Bookyear created successfully.",
          bookyear: result[:bookyear]
        }
      end
    end

    private

    def self.build_bookyear_data(params)
      data = {}

      data["description"] = params["description"] if params["description"]
      data["startDate"] = params["start_date"] if params["start_date"]
      data["endDate"] = params["end_date"] if params["end_date"]
      data["numberOfPeriods"] = params["number_of_periods"].to_i if params["number_of_periods"]
      data["currencyCode"] = params["currency_code"] || "EUR"
      data["closed"] = params["closed"] unless params["closed"].nil?

      data
    end
  end
end