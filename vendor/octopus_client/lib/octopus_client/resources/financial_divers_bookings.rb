module OctopusClient
  class Client
    module FinancialDiversBookings
      # GET /dossiers/{dossierId}/financialdiversbookings — Get financial/divers bookings.
      def get_financial_divers_bookings(bookyear_key_id: nil, journal_key: nil, document_sequence_nr: nil)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/financialdiversbookings") do |req|
          req.params["bookyearKeyId"] = bookyear_key_id.to_i if bookyear_key_id
          req.params["journalKey"] = journal_key if journal_key
          req.params["documentSequenceNr"] = document_sequence_nr.to_i if document_sequence_nr
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/financialdiversbookings — Create a financial/divers booking.
      def create_financial_divers_booking(booking_data)
        ensure_dossier_connected!

        payload = { "financialDiversBookingServiceData" => booking_data }
        response = dossier_post("dossiers/#{@dossier_id}/financialdiversbookings", payload)
        handle_write_error!(response) unless [200, 201].include?(response.status)

        { status: "created" }
      end

      # PUT /dossiers/{dossierId}/financialdiversbookings — Update a financial/divers booking.
      def update_financial_divers_booking(booking_data)
        ensure_dossier_connected!

        response = dossier_put("dossiers/#{@dossier_id}/financialdiversbookings", booking_data)
        handle_write_error!(response) unless [200, 204].include?(response.status)

        upsert_result(response)
      end

      # GET /dossiers/{dossierId}/financialdiversbookings/modified
      def get_modified_financial_divers_bookings(bookyear_id:, journal_key: nil, modified_timestamp:)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/financialdiversbookings/modified") do |req|
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
