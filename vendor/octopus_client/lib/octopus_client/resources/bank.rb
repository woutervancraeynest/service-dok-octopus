module OctopusClient
  class Client
    module Bank
      # GET /dossiers/{dossierId}/bank/paymentlist — Retrieve the payment list.
      def get_payment_list
        ensure_dossier_connected!
        response = dossier_get("dossiers/#{@dossier_id}/bank/paymentlist")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/bank/paymentlist — Add an invoice to the payment list.
      def add_invoice_to_payment_list(document_data, amount: nil, reference: nil, iban: nil, bic: nil)
        ensure_dossier_connected!

        response = @connection.post("dossiers/#{@dossier_id}/bank/paymentlist") do |req|
          req.headers["dossierToken"] = @dossier_token
          req.params["amount"] = amount if amount
          req.params["reference"] = reference if reference
          req.params["iban"] = iban if iban
          req.params["bic"] = bic if bic
          req.body = document_data
        end

        handle_write_error!(response) unless response.success?
        { status: "created", body: response.body }
      end

      # POST /dossiers/{dossierId}/bank/paymentlist/freepayment — Add a free payment.
      def add_free_payment(payment_data)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/bank/paymentlist/freepayment", payment_data)
        handle_write_error!(response) unless response.success?
        { status: "created", body: response.body }
      end

      # DELETE /dossiers/{dossierId}/bank/paymentlist/{paymentListKeyId}
      def remove_payment_from_list(payment_list_key_id:)
        ensure_dossier_connected!
        response = dossier_delete("dossiers/#{@dossier_id}/bank/paymentlist/#{payment_list_key_id.to_i}")
        handle_write_error!(response) unless [200, 204].include?(response.status)
        { status: "deleted" }
      end

      # GET /dossiers/{dossierId}/bank/invoices — Retrieve unbalanced invoices.
      def get_unbalanced_invoices
        ensure_dossier_connected!
        response = dossier_get("dossiers/#{@dossier_id}/bank/invoices")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # GET /dossiers/{dossierId}/bank/enveloppes — Retrieve all envelopes.
      def get_envelopes
        ensure_dossier_connected!
        response = dossier_get("dossiers/#{@dossier_id}/bank/enveloppes")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/bank/enveloppes — Create a new envelope.
      def create_envelope(envelope_data)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/bank/enveloppes", envelope_data)
        handle_write_error!(response) unless response.success?
        { status: "created", body: response.body }
      end

      # GET /dossiers/{dossierId}/bank/enveloppes/{enveloppeKeyId} — Get envelope content.
      def get_envelope_content(envelope_key_id:)
        ensure_dossier_connected!
        response = dossier_get("dossiers/#{@dossier_id}/bank/enveloppes/#{envelope_key_id.to_i}")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # PUT /dossiers/{dossierId}/bank/enveloppes/{enveloppeKeyId} — Update an envelope.
      def update_envelope(envelope_key_id:, envelope_data:)
        ensure_dossier_connected!
        response = dossier_put("dossiers/#{@dossier_id}/bank/enveloppes/#{envelope_key_id.to_i}", envelope_data)
        handle_write_error!(response) unless response.success?
        upsert_result(response)
      end

      # DELETE /dossiers/{dossierId}/bank/enveloppes/{enveloppeKeyId} — Remove an envelope.
      def remove_envelope(envelope_key_id:)
        ensure_dossier_connected!
        response = dossier_delete("dossiers/#{@dossier_id}/bank/enveloppes/#{envelope_key_id.to_i}")
        handle_write_error!(response) unless [200, 204].include?(response.status)
        { status: "deleted" }
      end

      # POST /dossiers/{dossierId}/bank/enveloppes/{enveloppeKeyId}/add
      def add_payment_to_envelope(envelope_key_id:, payment_data:)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/bank/enveloppes/#{envelope_key_id.to_i}/add", payment_data)
        handle_write_error!(response) unless response.success?
        { status: "created", body: response.body }
      end

      # POST /dossiers/{dossierId}/bank/enveloppes/{enveloppeKeyId}/remove
      def remove_payment_from_envelope(envelope_key_id:, payment_data:)
        ensure_dossier_connected!
        response = dossier_post("dossiers/#{@dossier_id}/bank/enveloppes/#{envelope_key_id.to_i}/remove", payment_data)
        handle_write_error!(response) unless response.success?
        { status: "removed", body: response.body }
      end

      # POST /dossiers/{dossierId}/bank/enveloppes/{enveloppeKeyId}/export
      def export_envelope(envelope_key_id:, export_data:)
        ensure_dossier_connected!

        response = @connection.post("dossiers/#{@dossier_id}/bank/enveloppes/#{envelope_key_id.to_i}/export") do |req|
          req.headers["dossierToken"] = @dossier_token
          req.body = export_data
        end

        handle_write_error!(response) unless response.success?
        response.body
      end
    end
  end
end
