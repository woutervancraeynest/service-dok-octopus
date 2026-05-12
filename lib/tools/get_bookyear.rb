# Get a specific bookyear by ID from the configured Octopus dossier.
#
# Returns bookyear details including description, start/end dates, periods,
# and whether it is closed.
#
module Tools
  class GetBookyear
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide a bookyear_id." }
      end

      with_dossier_connection(context) do |client|
        result = client.get_bookyear(bookyear_id: params["bookyear_id"].to_i)

        {
          bookyear: result
        }
      end
    end
  end
end