module OctopusClient
  class Client
    module BuySellBookings
      # GET /dossiers/{dossierId}/buysellbookings — Get buy/sell bookings.
      #
      # Falls back to the /modified endpoint when the standard endpoint
      # returns HTTP 400 (a known Octopus API quirk on some dossiers).
      def get_buy_sell_bookings(bookyear_key_id: nil, journal_key: nil, document_sequence_nr: nil)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/buysellbookings") do |req|
          req.params["bookyearKeyId"] = bookyear_key_id.to_i if bookyear_key_id
          req.params["journalKey"] = journal_key if journal_key
          req.params["documentSequenceNr"] = document_sequence_nr.to_i if document_sequence_nr
        end

        if response.status == 400
          return fallback_modified_buy_sell_bookings(
            bookyear_key_id: bookyear_key_id, journal_key: journal_key,
            document_sequence_nr: document_sequence_nr
          )
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/buysellbookings — Create a buy/sell booking.
      def create_buy_sell_booking(booking_data)
        ensure_dossier_connected!

        payload = { "buySellBookingServiceData" => booking_data }
        response = dossier_post("dossiers/#{@dossier_id}/buysellbookings", payload)
        handle_write_error!(response) unless [200, 201].include?(response.status)

        { status: "created", body: response.body }
      end

      # PUT /dossiers/{dossierId}/buysellbookings — Update a buy/sell booking.
      def update_buy_sell_booking(booking_data)
        ensure_dossier_connected!

        response = dossier_put("dossiers/#{@dossier_id}/buysellbookings", booking_data)
        handle_write_error!(response) unless [200, 204].include?(response.status)

        upsert_result(response)
      end

      # GET /dossiers/{dossierId}/buysellbookings/modified — Get modified buy/sell bookings.
      def get_modified_buy_sell_bookings(bookyear_id:, journal_key: nil, modified_timestamp:)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/buysellbookings/modified") do |req|
          req.params["bookyearId"] = bookyear_id.to_i
          req.params["journalKey"] = journal_key if journal_key
          req.params["modifiedTimeStamp"] = modified_timestamp
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end

      private

      def fallback_modified_buy_sell_bookings(bookyear_key_id:, journal_key:, document_sequence_nr:)
        result = get_modified_buy_sell_bookings(
          bookyear_id: bookyear_key_id || -1,
          journal_key: journal_key,
          modified_timestamp: "2000-01-01 00:00:00.000"
        )
        return result unless document_sequence_nr && result.is_a?(Array)

        result.select { |b| b["documentSequenceNr"] == document_sequence_nr.to_i }
      end
    end
  end
end
