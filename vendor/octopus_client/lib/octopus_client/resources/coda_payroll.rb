module OctopusClient
  class Client
    module CodaPayroll
      # POST /dossiers/{dossierId}/coda — Import a CODA bank statement.
      def import_coda(coda_content, publish_pdf_in_dms: false)
        ensure_dossier_connected!

        response = @connection.post("dossiers/#{@dossier_id}/coda") do |req|
          req.headers["dossierToken"] = @dossier_token
          req.headers["Content-Type"] = "application/json"
          req.params["publishPdfInDms"] = publish_pdf_in_dms
          req.body = coda_content.is_a?(String) ? coda_content.to_json : coda_content
        end

        handle_write_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/payroll — Import a SODA payroll file.
      def import_soda(file_content)
        ensure_dossier_connected!

        response = @connection.post("dossiers/#{@dossier_id}/payroll") do |req|
          req.headers["dossierToken"] = @dossier_token
          req.headers["Content-Type"] = "application/octet-stream"
          req.body = file_content
        end

        handle_write_error!(response) unless response.success?
        response.body
      end
    end
  end
end
