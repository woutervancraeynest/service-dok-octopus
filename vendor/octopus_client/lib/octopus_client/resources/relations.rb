module OctopusClient
  class Client
    module Relations
      # GET /dossiers/{dossierId}/relations — Get all relations (clients/suppliers).
      def get_relations
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/relations")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # PUT /dossiers/{dossierId}/relations — Create or update a relation (upsert).
      def create_or_update_relation(relation_data)
        ensure_dossier_connected!

        response = dossier_put("dossiers/#{@dossier_id}/relations", relation_data)
        handle_write_error!(response) unless [200, 201, 204].include?(response.status)

        case response.status
        when 201
          { status: "created", relation: response.body }
        when 204
          { status: "updated" }
        else
          { status: "success", relation: response.body }
        end
      end

      # GET /dossiers/{dossierId}/relations/modified — Get modified relations.
      def get_modified_relations(modified_timestamp: nil)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/relations/modified") do |req|
          req.params["modifiedTimeStamp"] = modified_timestamp if modified_timestamp
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end
    end
  end
end
