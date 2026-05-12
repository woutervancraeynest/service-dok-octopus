# Get all VAT codes from the configured Octopus dossier.
#
# Returns VAT code details including codes, descriptions, and percentages.
#
module Tools
  class GetVatCodes
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        result = client.get_vat_codes

        return { vat_codes: [], total: 0 } if result.nil? || result.empty?

        {
          vat_codes: result,
          total: result.length
        }
      end
    end
  end
end