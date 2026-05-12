# Get the content of a specific payment envelope from the configured Octopus dossier.
#
# Returns envelope details including all payments contained within the envelope.
#
module Tools
  class GetEnvelopeContent
    extend OctopusAuth

    REQUIRED_PARAMS = %w[envelope_key_id].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide an envelope_key_id." }
      end

      with_dossier_connection(context) do |client|
        result = client.get_envelope_content(envelope_key_id: params["envelope_key_id"].to_i)

        {
          envelope: result
        }
      end
    end
  end
end