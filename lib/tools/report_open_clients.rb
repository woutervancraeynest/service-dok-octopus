# Generate an open clients report from the configured Octopus dossier.
#
# Returns open client data showing unpaid/unbalanced invoices per client.
# Useful for reconciliation: shows which client invoices are still outstanding.
#
module Tools
  class ReportOpenClients
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide a bookyear_id." }
      end

      with_dossier_connection(context) do |client|
        result = client.report_open_clients(
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
