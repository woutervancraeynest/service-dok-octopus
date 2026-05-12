require "faraday"
require "faraday/cookie_jar"
require "json"

require_relative "resources/about"
require_relative "resources/accounts"
require_relative "resources/balancings"
require_relative "resources/bank"
require_relative "resources/bookings"
require_relative "resources/bookyears"
require_relative "resources/buy_sell_bookings"
require_relative "resources/coda_payroll"
require_relative "resources/cost_centres"
require_relative "resources/delivery_notes"
require_relative "resources/dossiers"
require_relative "resources/financial_divers_bookings"
require_relative "resources/invoices"
require_relative "resources/journals"
require_relative "resources/products"
require_relative "resources/rappels"
require_relative "resources/reference_data"
require_relative "resources/relations"
require_relative "resources/reports"

module OctopusClient
  # Octopus REST API client — full coverage of the Octopus accounting API.
  #
  # Handles the two-step authentication flow:
  #   1. Authenticate (user/password + softwareHouseUuid) -> Auth Token (10 min)
  #   2. Connect to Dossier (auth token + dossierId) -> Dossier Token (10 min)
  #
  # All subsequent API calls require the Dossier Token in headers.
  #
  # Important: Octopus requires session cookies to be maintained between
  # authentication and dossier connection calls.
  #
  class Client
    DEFAULT_BASE_URL = "https://service.inaras.be/octopus-rest-api/v1"

    # Include all resource modules
    include About
    include Accounts
    include Balancings
    include Bank
    include Bookings
    include Bookyears
    include BuySellBookings
    include CodaPayroll
    include CostCentres
    include DeliveryNotes
    include Dossiers
    include FinancialDiversBookings
    include Invoices
    include Journals
    include Products
    include Rappels
    include ReferenceData
    include Relations
    include Reports

    attr_reader :auth_token, :dossier_token, :dossier_id, :base_url

    def initialize(user:, password:, software_house_id:, base_url: DEFAULT_BASE_URL)
      raise ConfigurationError, "Octopus user is required" if user.nil? || user.empty?
      raise ConfigurationError, "Octopus password is required" if password.nil? || password.empty?
      raise ConfigurationError, "Software House ID is required" if software_house_id.nil? || software_house_id.empty?

      @user = user
      @password = password
      @software_house_id = software_house_id
      @base_url = base_url
      @auth_token = nil
      @dossier_token = nil
      @dossier_id = nil

      @connection = Faraday.new(url: @base_url) do |f|
        f.request :json
        f.response :json, content_type: /\bjson$/
        f.use :cookie_jar
        f.adapter Faraday.default_adapter
      end
    end

    # =========================================================================
    # Authentication
    # =========================================================================

    # POST /authentication — Authenticate and obtain an auth token (valid 10 min).
    def authenticate
      response = @connection.post("authentication") do |req|
        req.headers["softwareHouseUuid"] = @software_house_id
        req.body = { user: @user, password: @password }
      end

      handle_auth_error!(response) unless response.success?

      @auth_token = response.body["token"]
      raise AuthenticationError, "No token received from Octopus" unless @auth_token

      @auth_token
    end

    # GET /authentication — Get user information from a token (whoami).
    def whoami
      ensure_authenticated!

      response = @connection.get("authentication") do |req|
        req.headers["Token"] = @auth_token
      end

      return handle_api_error!(response) unless response.success?
      response.body
    end

    # POST /dossiers?dossierId=X — Connect to a dossier (obtain dossier token).
    def connect_dossier(dossier_id)
      ensure_authenticated!

      response = @connection.post("dossiers") do |req|
        req.headers["Token"] = @auth_token
        req.params["dossierId"] = dossier_id.to_i
      end

      handle_api_error!(response) unless response.success?

      @dossier_token = response.body["Dossiertoken"] || response.body["dossiertoken"]
      @dossier_id = dossier_id.to_i

      raise ApiError, "No dossier token received from Octopus" unless @dossier_token

      @dossier_token
    end

    # Convenience: authenticate + connect to dossier in one call.
    def with_dossier(dossier_id)
      authenticate
      connect_dossier(dossier_id)
      yield self
    end

    private

    # =========================================================================
    # HTTP helpers
    # =========================================================================

    def dossier_get(path)
      @connection.get(path) do |req|
        req.headers["dossierToken"] = @dossier_token
        yield req if block_given?
      end
    end

    def dossier_post(path, body)
      @connection.post(path) do |req|
        req.headers["dossierToken"] = @dossier_token
        req.body = body
      end
    end

    def dossier_post_with_params(path, body, params)
      @connection.post(path) do |req|
        req.headers["dossierToken"] = @dossier_token
        params.each { |k, v| req.params[k] = v unless v.nil? }
        req.body = body if body
      end
    end

    def dossier_put(path, body)
      @connection.put(path) do |req|
        req.headers["dossierToken"] = @dossier_token
        req.body = body
      end
    end

    def dossier_delete(path)
      @connection.delete(path) do |req|
        req.headers["dossierToken"] = @dossier_token
      end
    end

    def dossier_delete_with_body(path, body)
      @connection.delete(path) do |req|
        req.headers["dossierToken"] = @dossier_token
        req.body = body
      end
    end

    # =========================================================================
    # Result helpers
    # =========================================================================

    def upsert_result(response)
      case response.status
      when 201
        { status: "created", body: response.body }
      when 204
        { status: "updated" }
      else
        { status: "success", body: response.body }
      end
    end

    # =========================================================================
    # Auth guards
    # =========================================================================

    def ensure_authenticated!
      raise AuthenticationError, "Not authenticated. Call authenticate first." unless @auth_token
    end

    def ensure_dossier_connected!
      raise ApiError, "Not connected to a dossier. Call connect_dossier first." unless @dossier_token
    end

    # =========================================================================
    # Error handlers
    # =========================================================================

    def handle_auth_error!(response)
      body = response.body
      message = if body.is_a?(Hash)
                  body["errorMessage"] || body["message"] || "Authentication failed"
                else
                  "Authentication failed"
                end

      case response.status
      when 401
        raise AuthenticationError, "Invalid credentials: #{message}"
      else
        raise AuthenticationError, "Authentication error (HTTP #{response.status}): #{message}"
      end
    end

    def handle_api_error!(response)
      body = response.body
      message = if body.is_a?(Hash)
                  body["errorMessage"] || body["message"] || "API request failed"
                else
                  "API request failed"
                end

      case response.status
      when 401
        raise AuthenticationError, "Token expired or invalid: #{message}"
      when 404
        return nil
      else
        raise ApiError, "Octopus API error (HTTP #{response.status}): #{message}"
      end
    end

    def handle_write_error!(response)
      body = response.body
      message = if body.is_a?(Hash)
                  body["errorMessage"] || body["message"] || "Write operation failed"
                else
                  "Write operation failed"
                end

      case response.status
      when 401
        raise AuthenticationError, "Token expired or invalid: #{message}"
      when 400
        raise ApiError, "Invalid or missing parameters: #{message}"
      when 403
        raise ApiError, "Journal is closed or in use by another user: #{message}"
      when 500
        raise ApiError, "Invalid data format (check dates, amounts, and codes): #{message}"
      else
        raise ApiError, "Octopus API error (HTTP #{response.status}): #{message}"
      end
    end
  end
end
