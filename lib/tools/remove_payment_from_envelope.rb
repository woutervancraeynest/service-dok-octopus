# Remove a payment from an envelope in the configured Octopus dossier.
#
# Removes a payment from an existing envelope, returning it to the general
# payment list.
#
module Tools
  class RemovePaymentFromEnvelope
    extend OctopusAuth

    REQUIRED_PARAMS = %w[envelope_key_id].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide an envelope_key_id." }
      end

      payment_data = build_payment_data(params)

      with_dossier_connection(context) do |client|
        result = client.remove_payment_from_envelope(
          envelope_key_id: params["envelope_key_id"].to_i,
          payment_data: payment_data
        )
        {
          status: "removed",
          message: "Payment removed from envelope successfully.",
          result: result
        }
      end
    end

    private

    def self.build_payment_data(params)
      data = {}

      data["paymentListKeyId"] = params["payment_list_key_id"].to_i if params["payment_list_key_id"]
      data["amount"] = params["amount"].to_f if params["amount"]
      data["reference"] = params["reference"] if params["reference"]

      data
    end
  end
end