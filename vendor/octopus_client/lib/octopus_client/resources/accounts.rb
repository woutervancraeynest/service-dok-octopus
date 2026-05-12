module OctopusClient
  class Client
    module Accounts
      # GET /dossiers/{dossierId}/accounts — Get accounts for a bookyear.
      def get_accounts(bookyear_id:)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/accounts") do |req|
          req.params["bookyearId"] = bookyear_id.to_i
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end

      # PUT /dossiers/{dossierId}/accounts — Create or update an account.
      def create_or_update_account(account_data)
        ensure_dossier_connected!

        response = dossier_put("dossiers/#{@dossier_id}/accounts", account_data)
        handle_write_error!(response) unless [200, 201, 204].include?(response.status)

        upsert_result(response)
      end

      # GET /dossiers/{dossierId}/accounts/modified — Get modified accounts.
      def get_modified_accounts(modified_timestamp:)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/accounts/modified") do |req|
          req.params["modifiedTimeStamp"] = modified_timestamp
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end

      # GET /dossiers/{dossierId}/accounts/amounts/modified — Get modified account amounts.
      def get_modified_account_amounts(modified_timestamp: nil)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/accounts/amounts/modified") do |req|
          req.params["modifiedTimeStamp"] = modified_timestamp if modified_timestamp
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end
    end
  end
end
