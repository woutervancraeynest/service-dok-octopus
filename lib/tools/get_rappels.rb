# Get rappel information from the configured Octopus dossier.
#
# Returns rappel details for invoices that are overdue as of the specified
# expiration date.
#
module Tools
  class GetRappels
    extend OctopusAuth

    REQUIRED_PARAMS = %w[expiration_date].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide an expiration_date." }
      end

      with_dossier_connection(context) do |client|
        result = client.get_rappels(expiration_date: params["expiration_date"])

        return { rappels: [], total: 0 } if result.nil? || result.empty?

        {
          rappels: result,
          total: result.length
        }
      end
    end
  end
end