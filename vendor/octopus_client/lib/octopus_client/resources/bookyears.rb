module OctopusClient
  class Client
    module Bookyears
      # GET /dossiers/{dossierId}/bookyears — Get all bookyears for a dossier.
      def get_bookyears
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/bookyears")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # GET /dossiers/{dossierId}/bookyears/{bookyearId} — Get a single bookyear.
      def get_bookyear(bookyear_id:)
        ensure_dossier_connected!

        response = dossier_get("dossiers/#{@dossier_id}/bookyears/#{bookyear_id.to_i}")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # POST /dossiers/{dossierId}/bookyears — Create a new bookyear.
      def create_bookyear(bookyear_data)
        ensure_dossier_connected!

        response = dossier_post("dossiers/#{@dossier_id}/bookyears", bookyear_data)
        handle_write_error!(response) unless [200, 201].include?(response.status)

        { status: "created", bookyear: response.body }
      end

      # PUT /dossiers/{dossierId}/bookyears — Update a bookyear.
      def update_bookyear(bookyear_data)
        ensure_dossier_connected!

        response = dossier_put("dossiers/#{@dossier_id}/bookyears", bookyear_data)
        handle_write_error!(response) unless [200, 204].include?(response.status)

        upsert_result(response)
      end

      # POST /dossiers/{dossierId}/bookyears/book — Book bookyear to the next bookyear.
      def book_bookyear(book_data)
        ensure_dossier_connected!

        response = dossier_post("dossiers/#{@dossier_id}/bookyears/book", book_data)
        handle_write_error!(response) unless [200, 201].include?(response.status)

        { status: "booked", body: response.body }
      end

      # POST /dossiers/{dossierId}/bookyears/{bookyearId}/close — Close a bookyear.
      def close_bookyear(bookyear_id:, copy_all_account_descriptions: false)
        ensure_dossier_connected!

        response = dossier_post_with_params(
          "dossiers/#{@dossier_id}/bookyears/#{bookyear_id.to_i}/close",
          nil,
          { "copyAllAccountDescriptions" => copy_all_account_descriptions }
        )
        handle_write_error!(response) unless [200, 201, 204].include?(response.status)

        { status: "closed" }
      end
    end
  end
end
