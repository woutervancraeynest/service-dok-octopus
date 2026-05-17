module OctopusClient
  class Client
    module Reports
      # POST /dossiers/{dossierId}/reports/accounts/history
      #
      # Accepts keyword args that are translated to the API body format.
      # The Octopus API requires fromBookyearKey and optionally toBookyearKey.
      def report_history_accounts(from_bookyear_id:, to_bookyear_id: nil,
                                   period_from: nil, period_to: nil, journal_key: nil, **extra)
        ensure_dossier_connected!
        query_data = build_report_query(from_bookyear_id, to_bookyear_id, period_from, period_to, journal_key, extra)
        response = dossier_post("dossiers/#{@dossier_id}/reports/accounts/history", query_data)
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/reports/accounts/open
      def report_open_accounts(from_bookyear_id:, to_bookyear_id: nil,
                                period_from: nil, period_to: nil, journal_key: nil, **extra)
        ensure_dossier_connected!
        query_data = build_report_query(from_bookyear_id, to_bookyear_id, period_from, period_to, journal_key, extra)
        response = dossier_post("dossiers/#{@dossier_id}/reports/accounts/open", query_data)
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/reports/clients/history
      def report_history_clients(from_bookyear_id:, to_bookyear_id: nil,
                                  period_from: nil, period_to: nil, journal_key: nil, **extra)
        ensure_dossier_connected!
        query_data = build_report_query(from_bookyear_id, to_bookyear_id, period_from, period_to, journal_key, extra)
        response = dossier_post("dossiers/#{@dossier_id}/reports/clients/history", query_data)
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/reports/clients/open
      def report_open_clients(from_bookyear_id:, to_bookyear_id: nil,
                               period_from: nil, period_to: nil, journal_key: nil, **extra)
        ensure_dossier_connected!
        query_data = build_report_query(from_bookyear_id, to_bookyear_id, period_from, period_to, journal_key, extra)
        response = dossier_post("dossiers/#{@dossier_id}/reports/clients/open", query_data)
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/reports/suppliers/history
      def report_history_suppliers(from_bookyear_id:, to_bookyear_id: nil,
                                    period_from: nil, period_to: nil, journal_key: nil, **extra)
        ensure_dossier_connected!
        query_data = build_report_query(from_bookyear_id, to_bookyear_id, period_from, period_to, journal_key, extra)
        response = dossier_post("dossiers/#{@dossier_id}/reports/suppliers/history", query_data)
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/reports/suppliers/open
      def report_open_suppliers(from_bookyear_id:, to_bookyear_id: nil,
                                 period_from: nil, period_to: nil, journal_key: nil, **extra)
        ensure_dossier_connected!
        query_data = build_report_query(from_bookyear_id, to_bookyear_id, period_from, period_to, journal_key, extra)
        response = dossier_post("dossiers/#{@dossier_id}/reports/suppliers/open", query_data)
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/reports/costcentres/history
      def report_history_cost_centres(from_bookyear_id:, to_bookyear_id: nil,
                                       period_from: nil, period_to: nil, journal_key: nil, **extra)
        ensure_dossier_connected!
        query_data = build_report_query(from_bookyear_id, to_bookyear_id, period_from, period_to, journal_key, extra)
        response = dossier_post("dossiers/#{@dossier_id}/reports/costcentres/history", query_data)
        return handle_api_error!(response) unless response.success?
        response.body
      end

      private

      # Build the standard report query body from keyword arguments.
      #
      # The Octopus API expects:
      #   { "fromBookyearKey": { "id": X }, "toBookyearKey": { "id": Y }, ... }
      def build_report_query(from_bookyear_id, to_bookyear_id, period_from, period_to, journal_key, extra)
        data = {
          "fromBookyearKey" => { "id" => from_bookyear_id.to_i },
          "toBookyearKey" => { "id" => (to_bookyear_id || from_bookyear_id).to_i }
        }

        data["periodeFrom"] = period_from.to_i if period_from
        data["periodeTo"] = period_to.to_i if period_to
        data["journalKey"] = journal_key if journal_key
        data.merge!(extra) if extra.any?

        data
      end
    end
  end
end
