# Send invoices from the configured Octopus dossier.
#
# Generates and sends invoices via email or other delivery methods.
#
module Tools
  class SendInvoices
    extend OctopusAuth

    def self.call(params:, context:)
      send_data = build_send_data(params)

      with_dossier_connection(context) do |client|
        result = client.send_invoices(send_data)
        {
          status: "sent",
          message: "Invoices sent successfully.",
          result: result
        }
      end
    end

    private

    def self.build_send_data(params)
      data = {}

      # Build send data based on the provided parameters
      data["bookyearId"] = params["bookyear_id"].to_i if params["bookyear_id"]
      data["journalKey"] = params["journal_key"] if params["journal_key"]
      data["fromDocumentSequenceNr"] = params["from_document_sequence_nr"].to_i if params["from_document_sequence_nr"]
      data["toDocumentSequenceNr"] = params["to_document_sequence_nr"].to_i if params["to_document_sequence_nr"]
      data["sendMethod"] = params["send_method"] if params["send_method"]
      data["emailSubject"] = params["email_subject"] if params["email_subject"]
      data["emailBody"] = params["email_body"] if params["email_body"]

      data
    end
  end
end