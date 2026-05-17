module OctopusClient
  class Client
    module Products
      # GET /dossiers/{dossierId}/products — Get all products.
      def get_products
        ensure_dossier_connected!
        response = dossier_get("dossiers/#{@dossier_id}/products")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # PUT /dossiers/{dossierId}/products — Create or update a product.
      def create_or_update_product(product_data)
        ensure_dossier_connected!
        response = dossier_put("dossiers/#{@dossier_id}/products", product_data)
        handle_write_error!(response) unless [200, 201, 204].include?(response.status)
        upsert_result(response)
      end

      # GET /dossiers/{dossierId}/productgroups — Get all product groups.
      #
      # Aliases: get_productgroups (deprecated — use get_product_groups)
      def get_product_groups
        ensure_dossier_connected!
        response = dossier_get("dossiers/#{@dossier_id}/productgroups")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      alias_method :get_productgroups, :get_product_groups
    end
  end
end
