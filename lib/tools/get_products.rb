# Get all products from the configured Octopus dossier.
#
# Returns product details including IDs, descriptions, prices, and settings.
#
module Tools
  class GetProducts
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        result = client.get_products

        return { products: [], total: 0 } if result.nil? || result.empty?

        {
          products: result,
          total: result.length
        }
      end
    end
  end
end