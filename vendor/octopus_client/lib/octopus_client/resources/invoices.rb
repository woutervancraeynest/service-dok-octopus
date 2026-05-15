module OctopusClient
  class Client
    module Invoices
      # GET /dossiers/{dossierId}/invoices — Get invoices.
      #
      # Falls back to the /modified endpoint when the standard endpoint
      # returns HTTP 400 (e.g. invoice module not activated, or API quirk).
      def get_invoices(bookyear_key_id: nil, journal_key: nil, document_sequence_nr: nil)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/invoices") do |req|
          req.params["bookyearKeyId"] = bookyear_key_id.to_i if bookyear_key_id
          req.params["journalKey"] = journal_key if journal_key
          req.params["documentSequenceNr"] = document_sequence_nr.to_i if document_sequence_nr
        end

        if response.status == 400
          return fallback_modified_invoices(
            bookyear_key_id: bookyear_key_id, journal_key: journal_key,
            document_sequence_nr: document_sequence_nr
          )
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/invoices — Create an invoice.
      def create_invoice(invoice_data)
        ensure_dossier_connected!

        response = dossier_post("dossiers/#{@dossier_id}/invoices", invoice_data)
        handle_write_error!(response) unless [200, 201].include?(response.status)

        { status: "created" }
      end

      # PUT /dossiers/{dossierId}/invoices — Update an invoice.
      def update_invoice(invoice_data)
        ensure_dossier_connected!

        response = dossier_put("dossiers/#{@dossier_id}/invoices", invoice_data)
        handle_write_error!(response) unless [200, 204].include?(response.status)

        upsert_result(response)
      end

      # GET /dossiers/{dossierId}/invoices/export — Export an invoice (PDF/eInvoice).
      def export_invoice(bookyear_id:, journal_key:, document_sequence_nr:,
                         return_invoice: true, return_pdf_document: false, return_e_invoice_xml: false)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/invoices/export") do |req|
          req.params["bookyearId"] = bookyear_id.to_i
          req.params["journalKey"] = journal_key
          req.params["documentSequenceNr"] = document_sequence_nr.to_i
          req.params["returnInvoice"] = return_invoice
          req.params["returnPdfDocument"] = return_pdf_document
          req.params["returnEInvoiceXml"] = return_e_invoice_xml
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/invoices/generate — Generate an invoice (server-side PDF).
      def generate_invoice(bookyear_id:, journal_key:, document_sequence_nr:,
                           return_invoice: true, publish_pdf_in_dms: false,
                           publish_e_invoice_in_dms: false,
                           return_pdf_document: false, return_e_invoice_xml: false)
        ensure_dossier_connected!

        response = dossier_post_with_params(
          "dossiers/#{@dossier_id}/invoices/generate",
          nil,
          {
            "bookyearId" => bookyear_id.to_i,
            "journalKey" => journal_key,
            "documentSequenceNr" => document_sequence_nr.to_i,
            "returnInvoice" => return_invoice,
            "publishPdfInDms" => publish_pdf_in_dms,
            "publishEInvoiceInDms" => publish_e_invoice_in_dms,
            "returnPdfDocument" => return_pdf_document,
            "returnEInvoiceXml" => return_e_invoice_xml
          }
        )

        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/invoices/book — Book through invoices.
      def book_invoices(bookyear_id:, journal_key:, to_document_sequence_nr: nil, attach_ubl: nil)
        ensure_dossier_connected!

        response = dossier_post_with_params(
          "dossiers/#{@dossier_id}/invoices/book",
          nil,
          {
            "bookyearId" => bookyear_id.to_i,
            "journalKey" => journal_key,
            "toDocumentSequenceNr" => to_document_sequence_nr&.to_i,
            "attachUbl" => attach_ubl
          }.compact
        )

        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/invoices/send — Generate and send invoices.
      def send_invoices(send_data)
        ensure_dossier_connected!

        response = dossier_post("dossiers/#{@dossier_id}/invoices/send", send_data)
        handle_write_error!(response) unless [200, 201].include?(response.status)

        response.body
      end

      # POST /dossiers/{dossierId}/invoices/send/testmail/{language} — Send test mail.
      def send_invoice_test_mail(language:, journal_key:, from_address:, to_address:)
        ensure_dossier_connected!

        response = @connection.post("dossiers/#{@dossier_id}/invoices/send/testmail/#{language}") do |req|
          req.headers["dossierToken"] = @dossier_token
          req.headers["fromAddress"] = from_address
          req.headers["toAddress"] = to_address
          req.params["journalKey"] = journal_key
        end

        handle_write_error!(response) unless [200, 201].include?(response.status)
        response.body
      end

      # POST /dossiers/{dossierId}/invoices/send/report/deliverystate
      def get_invoice_delivery_states(selection_data)
        ensure_dossier_connected!

        response = dossier_post("dossiers/#{@dossier_id}/invoices/send/report/deliverystate", selection_data)
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/invoices/attachments/upload
      def upload_invoice_attachment(bookyear_id:, journal_key:, document_sequence_nr:,
                                    file_name:, file_content:)
        ensure_dossier_connected!

        response = @connection.post("dossiers/#{@dossier_id}/invoices/attachments/upload") do |req|
          req.headers["dossierToken"] = @dossier_token
          req.headers["Content-Type"] = "application/octet-stream"
          req.headers["fileName"] = file_name
          req.params["bookyearId"] = bookyear_id.to_i
          req.params["journalKey"] = journal_key
          req.params["documentSequenceNr"] = document_sequence_nr.to_i
          req.body = file_content
        end

        handle_write_error!(response) unless [200, 201].include?(response.status)
        { status: "uploaded" }
      end

      # GET /dossiers/{dossierId}/invoices/modified — Get modified invoices.
      def get_modified_invoices(bookyear_id:, journal_key: nil, modified_timestamp:)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/invoices/modified") do |req|
          req.params["bookyearId"] = bookyear_id.to_i
          req.params["journalKey"] = journal_key if journal_key
          req.params["modifiedTimeStamp"] = modified_timestamp
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end

      private

      def fallback_modified_invoices(bookyear_key_id:, journal_key:, document_sequence_nr:)
        result = get_modified_invoices(
          bookyear_id: bookyear_key_id || -1,
          journal_key: journal_key,
          modified_timestamp: "2000-01-01 00:00:00.000"
        )
        return result unless document_sequence_nr && result.is_a?(Array)

        result.select { |inv| inv["documentSequenceNr"] == document_sequence_nr.to_i }
      end
    end
  end
end
