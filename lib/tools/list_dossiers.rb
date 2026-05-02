# List all Octopus dossiers accessible to the authenticated user.
#
# This tool only requires authentication (no dossier connection needed).
# Useful for discovering the correct dossier_id for project configuration.
#
module Tools
  class ListDossiers
    extend OctopusAuth

    def self.call(params:, context:)
      with_octopus_client(context) do |client|
        dossiers = client.list_dossiers

        return { dossiers: [], total: 0 } if dossiers.nil? || dossiers.empty?

        {
          dossiers: dossiers,
          total: dossiers.length
        }
      end
    end
  end
end
