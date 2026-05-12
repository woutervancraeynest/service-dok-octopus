module OctopusClient
  class Client
    module Dossiers
      # GET /dossiers — List all dossiers accessible to the authenticated user.
      # Uses auth token (not dossier token).
      def list_dossiers
        ensure_authenticated!

        response = @connection.get("dossiers") do |req|
          req.headers["Token"] = @auth_token
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end
    end
  end
end
