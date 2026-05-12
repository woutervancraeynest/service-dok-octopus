# Get unbalanced invoices from the configured Octopus dossier.
#
# Returns invoices that have not been fully paid or balanced.
#
module Tools
  class GetUnbalancedInvoices
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        result = client.get_unbalanced_invoices

        return { invoices: [], total: 0 } if result.nil? || result.empty?

        {
          invoices: result,
          total: result.length
        }
      end
    end
  end
end