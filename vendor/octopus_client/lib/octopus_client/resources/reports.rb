module OctopusClient
  class Client
    module Reports
      # POST /dossiers/{dossierId}/reports/accounts/history
      def report_history_accounts(query_data)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/reports/accounts/history", query_data)
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/reports/accounts/open
      def report_open_accounts(query_data)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/reports/accounts/open", query_data)
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/reports/clients/history
      def report_history_clients(query_data)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/reports/clients/history", query_data)
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/reports/clients/open
      def report_open_clients(query_data)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/reports/clients/open", query_data)
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/reports/suppliers/history
      def report_history_suppliers(query_data)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/reports/suppliers/history", query_data)
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/reports/suppliers/open
      def report_open_suppliers(query_data)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/reports/suppliers/open", query_data)
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/reports/costcentres/history
      def report_history_cost_centres(query_data)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/reports/costcentres/history", query_data)
        return handle_api_error!(response) unless response.success?
        response.body
      end
    end
  end
end
