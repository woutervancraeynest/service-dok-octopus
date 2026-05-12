# Export a rappel (reminder) as PDF from the configured Octopus dossier.
#
# Returns the rappel data including PDF content if requested.
#
module Tools
  class ExportRappel
    extend OctopusAuth

    REQUIRED_PARAMS = %w[relation_id rappel_id].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide relation_id and rappel_id." }
      end

      with_dossier_connection(context) do |client|
        result = client.export_rappel(
          relation_id: params["relation_id"].to_i,
          rappel_id: params["rappel_id"].to_i
        )

        {
          rappel: result
        }
      end
    end
  end
end