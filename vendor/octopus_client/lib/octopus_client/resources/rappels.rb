module OctopusClient
  class Client
    module Rappels
      # GET /dossiers/{dossierId}/rappels — Get rappel information.
      def get_rappels(expiration_date:)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/rappels") do |req|
          req.params["expirationDate"] = expiration_date
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end

      # GET /dossiers/{dossierId}/rappels/export — Export a rappel (PDF).
      def export_rappel(relation_id:, rappel_id:)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/rappels/export") do |req|
          req.params["relationId"] = relation_id.to_i
          req.params["rappelId"] = rappel_id.to_i
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end
    end
  end
end
