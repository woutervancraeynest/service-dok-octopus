module OctopusClient
  class Client
    module About
      # GET /about/version — Get API version number.
      def get_api_version
        response = @connection.get("about/version")
        return handle_api_error!(response) unless response.success?
        response.body
      end

      # GET /error — Generate a sample error for testing.
      def generate_error(error_code: nil)
        response = @connection.get("error") do |req|
          req.params["errorCode"] = error_code if error_code
        end

        return handle_api_error!(response) unless response.success?
        response.body
      end
    end
  end
end
