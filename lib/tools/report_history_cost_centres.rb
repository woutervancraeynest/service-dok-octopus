# Generate a history cost centres report from the configured Octopus dossier.
#
# Returns historical cost centre data for the specified period and bookyear range.
#
module Tools
  class ReportHistoryCostCentres
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide a bookyear_id." }
      end

      query_data = build_query_data(params)

      with_dossier_connection(context) do |client|
        result = client.report_history_cost_centres(query_data)

        return { report: [], total: 0 } if result.nil?

        {
          report: result,
          total: result.is_a?(Array) ? result.length : 1
        }
      end
    end

    private

    def self.build_query_data(params)
      from_id = params["bookyear_id"].to_i
      to_id = (params["to_bookyear_id"] || params["bookyear_id"]).to_i

      data = {
        "fromBookyearKey" => { "id" => from_id },
        "toBookyearKey" => { "id" => to_id }
      }

      data["periodeFrom"] = params["period_from"].to_i if params["period_from"]
      data["periodeTo"] = params["period_to"].to_i if params["period_to"]
      data["journalKey"] = params["journal_key"] if params["journal_key"]

      data
    end
  end
end
