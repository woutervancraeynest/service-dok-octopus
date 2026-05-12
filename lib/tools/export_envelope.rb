# Export an envelope from the configured Octopus dossier.
#
# Exports an envelope with all its payments for external processing or archiving.
#
module Tools
  class ExportEnvelope
    extend OctopusAuth

    REQUIRED_PARAMS = %w[envelope_key_id].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide an envelope_key_id." }
      end

      export_data = build_export_data(params)

      with_dossier_connection(context) do |client|
        result = client.export_envelope(
          envelope_key_id: params["envelope_key_id"].to_i,
          export_data: export_data
        )
        {
          export: result
        }
      end
    end

    private

    def self.build_export_data(params)
      data = {}

      data["format"] = params["format"] if params["format"]
      data["includePayments"] = params["include_payments"] unless params["include_payments"].nil?
      data["exportDate"] = params["export_date"] if params["export_date"]

      data
    end
  end
end