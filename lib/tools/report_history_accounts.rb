# Generate a history accounts report from the configured Octopus dossier.
#
# Returns historical account data for the specified period and bookyear.
#
module Tools
  class ReportHistoryAccounts
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide a bookyear_id." }
      end

      query_data = build_query_data(params)

      with_dossier_connection(context) do |client|
        result = client.report_history_accounts(query_data)

        {
          report: result
        }
      end
    end

    private

    def self.build_query_data(params)
      data = {
        "bookyearKey" => { "id" => params["bookyear_id"].to_i }
      }

      data["periodeFrom"] = params["period_from"].to_i if params["period_from"]
      data["periodeTo"] = params["period_to"].to_i if params["period_to"]
      data["journalKey"] = params["journal_key"] if params["journal_key"]

      data
    end
  end
end