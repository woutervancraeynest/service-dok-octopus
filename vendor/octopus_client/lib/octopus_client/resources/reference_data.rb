module OctopusClient
  class Client
    module ReferenceData
      # GET /dossiers/{dossierId}/vatcodes — Get VAT codes.
      def get_vat_codes
        ensure_dossier_connected!
        response = dossier_get("dossiers/#{@dossier_id}/vatcodes")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # GET /dossiers/{dossierId}/currencies — Get currency codes.
      def get_currencies
        ensure_dossier_connected!
        response = dossier_get("dossiers/#{@dossier_id}/currencies")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # GET /dossiers/{dossierId}/customfields — Get custom fields.
      def get_custom_fields
        ensure_dossier_connected!
        response = dossier_get("dossiers/#{@dossier_id}/customfields")
        return handle_api_error!(response) unless response.success?
        response.body
      end
    end
  end
end
