# Get the payment list from the configured Octopus dossier.
#
# Returns all payments in the payment list including amounts, references,
# and bank details.
#
module Tools
  class GetPaymentList
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        result = client.get_payment_list

        return { payments: [], total: 0 } if result.nil? || result.empty?

        {
          payments: result,
          total: result.length
        }
      end
    end
  end
end