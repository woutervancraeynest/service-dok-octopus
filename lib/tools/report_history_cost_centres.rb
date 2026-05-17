# Generate a history cost centres report from the configured Octopus dossier.
#
# Returns historical cost centre data for the specified bookyear range.
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

      with_dossier_connection(context) do |client|
        result = client.report_history_cost_centres(
          from_bookyear_id: params["bookyear_id"].to_i,
          to_bookyear_id: (params["to_bookyear_id"] || params["bookyear_id"]).to_i,
          period_from: params["period_from"],
          period_to: params["period_to"],
          journal_key: params["journal_key"]
        )

        return { report: [], total: 0 } if result.nil?

        {
          report: result,
          total: result.is_a?(Array) ? result.length : 1
        }
      end
    end
  end
end
