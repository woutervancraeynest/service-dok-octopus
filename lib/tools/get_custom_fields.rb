# Get all custom fields from the configured Octopus dossier.
#
# Returns custom field definitions including names, types, and settings.
#
module Tools
  class GetCustomFields
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        result = client.get_custom_fields

        return { custom_fields: [], total: 0 } if result.nil? || result.empty?

        {
          custom_fields: result,
          total: result.length
        }
      end
    end
  end
end