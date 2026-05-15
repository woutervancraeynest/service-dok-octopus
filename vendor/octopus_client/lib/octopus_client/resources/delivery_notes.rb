module OctopusClient
  class Client
    module DeliveryNotes
      # GET /dossiers/{dossierId}/deliverynotes — Get delivery notes.
      #
      # Falls back to the /modified endpoint when the standard endpoint
      # returns HTTP 400 (a known Octopus API quirk on some dossiers).
      def get_delivery_notes(bookyear_key_id: nil, journal_key: nil, document_sequence_nr: nil)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/deliverynotes") do |req|
          req.params["bookyearKeyId"] = bookyear_key_id.to_i if bookyear_key_id
          req.params["journalKey"] = journal_key if journal_key
          req.params["documentSequenceNr"] = document_sequence_nr.to_i if document_sequence_nr
        end

        if response.status == 400
          return fallback_modified_delivery_notes(
            bookyear_key_id: bookyear_key_id, journal_key: journal_key,
            document_sequence_nr: document_sequence_nr
          )
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/deliverynotes — Create a delivery note.
      def create_delivery_note(delivery_note_data)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/deliverynotes", delivery_note_data)
        handle_write_error!(response) unless [200, 201].include?(response.status)
        { status: "created" }
      end

      # PUT /dossiers/{dossierId}/deliverynotes — Update a delivery note.
      def update_delivery_note(delivery_note_data)
        ensure_dossier_connected!
        response = dossier_put("dossiers/#{@dossier_id}/deliverynotes", delivery_note_data)
        handle_write_error!(response) unless [200, 204].include?(response.status)
        upsert_result(response)
      end

      # GET /dossiers/{dossierId}/deliverynotes/export — Export a delivery note (PDF).
      def export_delivery_note(bookyear_id:, journal_key:, document_sequence_nr:,
                               return_delivery_note: true, return_pdf_document: false)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/deliverynotes/export") do |req|
          req.params["bookyearId"] = bookyear_id.to_i
          req.params["journalKey"] = journal_key
          req.params["documentSequenceNr"] = document_sequence_nr.to_i
          req.params["returnDeliveryNote"] = return_delivery_note
          req.params["returnPdfDocument"] = return_pdf_document
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/deliverynotes/generate — Generate a delivery note (PDF).
      def generate_delivery_note(bookyear_id:, journal_key:, document_sequence_nr:,
                                 return_delivery_note: true, publish_pdf_in_dms: false,
                                 return_pdf_document: false)
        ensure_dossier_connected!

        response = dossier_post_with_params(
          "dossiers/#{@dossier_id}/deliverynotes/generate",
          nil,
          {
            "bookyearId" => bookyear_id.to_i,
            "journalKey" => journal_key,
            "documentSequenceNr" => document_sequence_nr.to_i,
            "returnDeliveryNote" => return_delivery_note,
            "publishPdfInDms" => publish_pdf_in_dms,
            "returnPdfDocument" => return_pdf_document
          }
        )

        return handle_api_error!(response) unless response.success?
        response.body
      end

      # GET /dossiers/{dossierId}/deliverynotes/modified — Get modified delivery notes.
      def get_modified_delivery_notes(bookyear_id:, journal_key: nil, modified_timestamp:)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/deliverynotes/modified") do |req|
          req.params["bookyearId"] = bookyear_id.to_i
          req.params["journalKey"] = journal_key if journal_key
          req.params["modifiedTimeStamp"] = modified_timestamp
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end

      private

      def fallback_modified_delivery_notes(bookyear_key_id:, journal_key:, document_sequence_nr:)
        result = get_modified_delivery_notes(
          bookyear_id: bookyear_key_id || -1,
          journal_key: journal_key,
          modified_timestamp: "2000-01-01 00:00:00.000"
        )
        return result unless document_sequence_nr && result.is_a?(Array)

        result.select { |n| n["documentSequenceNr"] == document_sequence_nr.to_i }
      end
    end
  end
end
