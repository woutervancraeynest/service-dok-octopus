module OctopusClient
  class Client
    module BuySellBookings
      # GET /dossiers/{dossierId}/buysellbookings — Get buy/sell bookings.
      def get_buy_sell_bookings(bookyear_key_id: nil, journal_key: nil, document_sequence_nr: nil)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/buysellbookings") do |req|
          req.params["bookyearKeyId"] = bookyear_key_id.to_i if bookyear_key_id
          req.params["journalKey"] = journal_key if journal_key
          req.params["documentSequenceNr"] = document_sequence_nr.to_i if document_sequence_nr
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

        { status: "created" }
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
    end
  end
end
