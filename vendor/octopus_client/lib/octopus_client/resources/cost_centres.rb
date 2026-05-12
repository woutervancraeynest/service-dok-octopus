module OctopusClient
  class Client
    module CostCentres
      # GET /dossiers/{dossierId}/costcentres — Get all cost centres.
      def get_cost_centres
        ensure_dossier_connected!
        response = dossier_get("dossiers/#{@dossier_id}/costcentres")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # GET /dossiers/{dossierId}/costcentres/active — Get active (not closed) cost centres.
      def get_active_cost_centres
        ensure_dossier_connected!
        response = dossier_get("dossiers/#{@dossier_id}/costcentres/active")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # PUT /dossiers/{dossierId}/costcentres — Create or update a cost centre.
      def create_or_update_cost_centre(cost_centre_data)
        ensure_dossier_connected!
        response = dossier_put("dossiers/#{@dossier_id}/costcentres", cost_centre_data)
        handle_write_error!(response) unless [200, 201, 204].include?(response.status)
        upsert_result(response)
      end
    end
  end
end
