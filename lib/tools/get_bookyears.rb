# Get all bookyears for the configured Octopus dossier.
#
# Returns bookyear IDs, descriptions, date ranges, and periods.
# The bookyear ID is needed for other tools (accounts, journals, bookings).
#
module Tools
  class GetBookyears
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        bookyears = client.get_bookyears

        return { bookyears: [], total: 0 } if bookyears.nil? || bookyears.empty?

        {
          bookyears: bookyears,
          total: bookyears.length
        }
      end
    end
  end
end
