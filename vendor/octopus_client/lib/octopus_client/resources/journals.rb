module OctopusClient
  class Client
    module Journals
      # GET /dossiers/{dossierId}/bookyears/{bookyearId}/journals — Get journals.
      #
      # Falls back to the /modified endpoint when the standard endpoint
      # returns HTTP 400 (a known Octopus API quirk on some dossiers).
      def get_journals(bookyear_id:)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/bookyears/#{bookyear_id.to_i}/journals")

        if response.status == 400
          return fallback_modified_journals
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end

      # GET /dossiers/{dossierId}/bookyears/{bookyearId}/journals/{journalKey}
      # Get financial journal balance.
      def get_financial_journal_balance(bookyear_id:, journal_key:)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/bookyears/#{bookyear_id.to_i}/journals/#{journal_key}")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # GET /dossiers/{dossierId}/bookyears/{bookyearId}/journals/A/{sequenceNumber}
      def get_buy_journal(bookyear_id:, sequence_number:)
        ensure_dossier_connected!
        response = dossier_get("dossiers/#{@dossier_id}/bookyears/#{bookyear_id.to_i}/journals/A/#{sequence_number.to_i}")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # GET /dossiers/{dossierId}/bookyears/{bookyearId}/journals/V/{sequenceNumber}
      def get_sell_journal(bookyear_id:, sequence_number:)
        ensure_dossier_connected!
        response = dossier_get("dossiers/#{@dossier_id}/bookyears/#{bookyear_id.to_i}/journals/V/#{sequence_number.to_i}")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # GET /dossiers/{dossierId}/bookyears/{bookyearId}/journals/F/{sequenceNumber}
      def get_financial_journal(bookyear_id:, sequence_number:)
        ensure_dossier_connected!
        response = dossier_get("dossiers/#{@dossier_id}/bookyears/#{bookyear_id.to_i}/journals/F/#{sequence_number.to_i}")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # GET /dossiers/{dossierId}/bookyears/{bookyearId}/journals/D/{sequenceNumber}
      def get_divers_journal(bookyear_id:, sequence_number:)
        ensure_dossier_connected!
        response = dossier_get("dossiers/#{@dossier_id}/bookyears/#{bookyear_id.to_i}/journals/D/#{sequence_number.to_i}")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # GET /dossiers/{dossierId}/bookyears/{bookyearId}/journals/L/{sequenceNumber}
      def get_delivery_journal(bookyear_id:, sequence_number:)
        ensure_dossier_connected!
        response = dossier_get("dossiers/#{@dossier_id}/bookyears/#{bookyear_id.to_i}/journals/L/#{sequence_number.to_i}")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/journals/A — Create a buy journal.
      def create_buy_journal(journal_data)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/journals/A", journal_data)
        handle_write_error!(response) unless [200, 201].include?(response.status)
        { status: "created", body: response.body }
      end

      # PUT /dossiers/{dossierId}/journals/A — Update a buy journal.
      def update_buy_journal(journal_data)
        ensure_dossier_connected!
        response = dossier_put("dossiers/#{@dossier_id}/journals/A", journal_data)
        handle_write_error!(response) unless [200, 204].include?(response.status)
        upsert_result(response)
      end

      # POST /dossiers/{dossierId}/journals/V — Create a sell journal.
      def create_sell_journal(journal_data)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/journals/V", journal_data)
        handle_write_error!(response) unless [200, 201].include?(response.status)
        { status: "created", body: response.body }
      end

      # PUT /dossiers/{dossierId}/journals/V — Update a sell journal.
      def update_sell_journal(journal_data)
        ensure_dossier_connected!
        response = dossier_put("dossiers/#{@dossier_id}/journals/V", journal_data)
        handle_write_error!(response) unless [200, 204].include?(response.status)
        upsert_result(response)
      end

      # POST /dossiers/{dossierId}/journals/F — Create a financial journal.
      def create_financial_journal(journal_data)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/journals/F", journal_data)
        handle_write_error!(response) unless [200, 201].include?(response.status)
        { status: "created", body: response.body }
      end

      # PUT /dossiers/{dossierId}/journals/F — Update a financial journal.
      def update_financial_journal(journal_data)
        ensure_dossier_connected!
        response = dossier_put("dossiers/#{@dossier_id}/journals/F", journal_data)
        handle_write_error!(response) unless [200, 204].include?(response.status)
        upsert_result(response)
      end

      # POST /dossiers/{dossierId}/journals/D — Create a divers journal.
      def create_divers_journal(journal_data)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/journals/D", journal_data)
        handle_write_error!(response) unless [200, 201].include?(response.status)
        { status: "created", body: response.body }
      end

      # PUT /dossiers/{dossierId}/journals/D — Update a divers journal.
      def update_divers_journal(journal_data)
        ensure_dossier_connected!
        response = dossier_put("dossiers/#{@dossier_id}/journals/D", journal_data)
        handle_write_error!(response) unless [200, 204].include?(response.status)
        upsert_result(response)
      end

      # POST /dossiers/{dossierId}/journals/L — Create a delivery journal.
      def create_delivery_journal(journal_data)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/journals/L", journal_data)
        handle_write_error!(response) unless [200, 201].include?(response.status)
        { status: "created", body: response.body }
      end

      # PUT /dossiers/{dossierId}/journals/L — Update a delivery journal.
      def update_delivery_journal(journal_data)
        ensure_dossier_connected!
        response = dossier_put("dossiers/#{@dossier_id}/journals/L", journal_data)
        handle_write_error!(response) unless [200, 204].include?(response.status)
        upsert_result(response)
      end

      # DELETE /dossiers/{dossierId}/bookyears/{bookyearId}/journals/{journalTypeCode}/{sequenceNumber}
      def delete_journal(bookyear_id:, journal_type_code:, sequence_number:)
        ensure_dossier_connected!
        path = "dossiers/#{@dossier_id}/bookyears/#{bookyear_id.to_i}/journals/#{journal_type_code}/#{sequence_number.to_i}"
        response = dossier_delete(path)
        handle_write_error!(response) unless [200, 204].include?(response.status)
        { status: "deleted" }
      end

      # GET /dossiers/{dossierId}/journals/modified — Get modified journals.
      def get_modified_journals(modified_timestamp:)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/journals/modified") do |req|
          req.params["modifiedTimeStamp"] = modified_timestamp
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end

      private

      def fallback_modified_journals
        get_modified_journals(modified_timestamp: "2000-01-01 00:00:00.000")
      end
    end
  end
end
