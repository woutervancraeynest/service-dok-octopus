# Get all currencies from the configured Octopus dossier.
#
# Returns currency details including codes and descriptions.
#
module Tools
  class GetCurrencies
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        result = client.get_currencies

        return { currencies: [], total: 0 } if result.nil? || result.empty?

        {
          currencies: result,
          total: result.length
        }
      end
    end
  end
end