module OctopusClient
  class Client
    module Balancings
      # POST /dossiers/{dossierId}/balancings — Insert a balancing.
      #
      # Alias: create_balancing
      def insert_balancing(balancing_data)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/balancings", balancing_data)
        handle_write_error!(response) unless [200, 201].include?(response.status)
        { status: "created", body: response.body }
      end

      alias_method :create_balancing, :insert_balancing

      # DELETE /dossiers/{dossierId}/balancings/delete — Delete a balancing.
      def delete_balancing(balancing_item_data)
        ensure_dossier_connected!
        response = dossier_delete_with_body("dossiers/#{@dossier_id}/balancings/delete", balancing_item_data)
        handle_write_error!(response) unless [200, 204].include?(response.status)
        { status: "deleted" }
      end

      # DELETE /dossiers/{dossierId}/balancings/bookingline/delete
      def delete_balancing_by_bookingline(balancing_key_data)
        ensure_dossier_connected!
        response = dossier_delete_with_body("dossiers/#{@dossier_id}/balancings/bookingline/delete", balancing_key_data)
        handle_write_error!(response) unless [200, 204].include?(response.status)
        { status: "deleted" }
      end

      # DELETE /dossiers/{dossierId}/balancings/document/delete
      def delete_balancing_by_document(document_key_data)
        ensure_dossier_connected!
        response = dossier_delete_with_body("dossiers/#{@dossier_id}/balancings/document/delete", document_key_data)
        handle_write_error!(response) unless [200, 204].include?(response.status)
        { status: "deleted" }
      end

      # GET /dossiers/{dossierId}/balancings/modified — Get modified balancings.
      def get_modified_balancings(modified_timestamp:)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/balancings/modified") do |req|
          req.params["modifiedTimeStamp"] = modified_timestamp
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end
    end
  end
end
