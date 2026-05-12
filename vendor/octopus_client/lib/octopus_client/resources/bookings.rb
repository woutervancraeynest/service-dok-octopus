module OctopusClient
  class Client
    module Bookings
      # POST /dossiers/{dossierId}/bookyears/{bookyearId}/bookings/attachements
      def add_booking_attachment(bookyear_id:, attachment_data:)
        ensure_dossier_connected!

        response = dossier_post(
          "dossiers/#{@dossier_id}/bookyears/#{bookyear_id.to_i}/bookings/attachements",
          attachment_data
        )
        handle_write_error!(response) unless [200, 201].include?(response.status)

        { status: "created" }
      end

      # GET /dossiers/{dossierId}/bookyears/{bookyearId}/bookings/modified
      def get_modified_bookings(bookyear_id:, journal_type_id:, modified_timestamp:)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/bookyears/#{bookyear_id.to_i}/bookings/modified") do |req|
          req.params["journalTypeId"] = journal_type_id.to_i
          req.params["modifiedTimeStamp"] = modified_timestamp
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end
    end
  end
end
