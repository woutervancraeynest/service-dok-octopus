require "faraday"
require "faraday/cookie_jar"
require "json"

# Octopus REST API client.
#
# Handles the two-step authentication flow:
#   1. Authenticate (user/password + softwareHouseUuid) → Auth Token (10 min)
#   2. Connect to Dossier (auth token + dossierId) → Dossier Token (10 min)
#
# All subsequent API calls require the Dossier Token in headers.
#
# Important: Octopus requires session cookies to be maintained between
# authentication and dossier connection calls.
#
module OctopusClient
  BASE_URL = "https://service.inaras.be/octopus-rest-api/v1"

  class AuthenticationError < StandardError; end
  class ApiError < StandardError; end
  class ConfigurationError < StandardError; end

  class Client
    attr_reader :auth_token, :dossier_token, :dossier_id

    def initialize(user:, password:, software_house_id:)
      raise ConfigurationError, "Octopus user is required" if user.nil? || user.empty?
      raise ConfigurationError, "Octopus password is required" if password.nil? || password.empty?
      raise ConfigurationError, "Software House ID is required" if software_house_id.nil? || software_house_id.empty?

      @user = user
      @password = password
      @software_house_id = software_house_id
      @auth_token = nil
      @dossier_token = nil
      @dossier_id = nil

      # Faraday connection with cookie jar to maintain session cookies.
      # Octopus requires cookies between auth and dossier-connect calls.
      @connection = Faraday.new(url: BASE_URL) do |f|
        f.request :json
        f.response :json, content_type: /\bjson$/
        f.use :cookie_jar
        f.adapter Faraday.default_adapter
      end
    end

    # Step 1: Authenticate and obtain an auth token (valid 10 minutes).
    #
    # POST /authentication
    # Header: softwareHouseUuid
    # Body: { user, password }
    #
    # Returns the auth token string.
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

    # Step 2: Connect to a dossier and obtain a dossier token (valid 10 minutes).
    #
    # POST /dossiers?dossierId=X
    # Header: Token (auth token)
    #
    # Returns the dossier token string.
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
    # Yields the client for making API calls, returns the block result.
    def with_dossier(dossier_id)
      authenticate
      connect_dossier(dossier_id)
      yield self
    end

    # --- Read endpoints ---

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

    # GET /dossiers/{dossierId}/bookyears — Get bookyears for a dossier.
    def get_bookyears
      ensure_dossier_connected!

      response = dossier_get("dossiers/#{@dossier_id}/bookyears")
      return handle_api_error!(response) unless response.success?
      response.body
    end

    # GET /dossiers/{dossierId}/relations — Get all relations (clients/suppliers).
    def get_relations
      ensure_dossier_connected!

      response = dossier_get("dossiers/#{@dossier_id}/relations")
      return handle_api_error!(response) unless response.success?
      response.body
    end

    # GET /dossiers/{dossierId}/accounts — Get accounts for a bookyear.
    # Requires bookyear_id parameter.
    def get_accounts(bookyear_id:)
      ensure_dossier_connected!

      response = dossier_get("dossiers/#{@dossier_id}/accounts") do |req|
        req.params["bookyearId"] = bookyear_id.to_i
      end

      return handle_api_error!(response) unless response.success?
      response.body
    end

    # GET /dossiers/{dossierId}/bookyears/{bookyearId}/journals — Get journals.
    def get_journals(bookyear_id:)
      ensure_dossier_connected!

      response = dossier_get("dossiers/#{@dossier_id}/bookyears/#{bookyear_id.to_i}/journals")
      return handle_api_error!(response) unless response.success?
      response.body
    end

    # GET /dossiers/{dossierId}/buysellbookings — Get buy/sell bookings.
    # Optional filters: bookyear_key_id, journal_key, document_sequence_nr
    def get_buy_sell_bookings(bookyear_key_id: nil, journal_key: nil, document_sequence_nr: nil)
      ensure_dossier_connected!

      response = dossier_get("dossiers/#{@dossier_id}/buysellbookings") do |req|
        req.params["bookyearKeyId"] = bookyear_key_id.to_i if bookyear_key_id
        req.params["journalKey"] = journal_key if journal_key
        req.params["documentSequenceNr"] = document_sequence_nr.to_i if document_sequence_nr
      end

      return handle_api_error!(response) unless response.success?
      response.body
    end

    # GET /dossiers/{dossierId}/invoices — Get invoices.
    # Optional filters: bookyear_key_id, journal_key, document_sequence_nr
    def get_invoices(bookyear_key_id: nil, journal_key: nil, document_sequence_nr: nil)
      ensure_dossier_connected!

      response = dossier_get("dossiers/#{@dossier_id}/invoices") do |req|
        req.params["bookyearKeyId"] = bookyear_key_id.to_i if bookyear_key_id
        req.params["journalKey"] = journal_key if journal_key
        req.params["documentSequenceNr"] = document_sequence_nr.to_i if document_sequence_nr
      end

      return handle_api_error!(response) unless response.success?
      response.body
    end

    # --- Write endpoints ---

    # PUT /dossiers/{dossierId}/relations — Create or update a relation.
    # Octopus uses PUT for upsert: if relationKey or externalRelationId matches
    # an existing relation, it updates; otherwise creates a new one.
    #
    # Returns { status: "created" } or { status: "updated" }.
    def create_or_update_relation(relation_data)
      ensure_dossier_connected!

      response = dossier_put("dossiers/#{@dossier_id}/relations", relation_data)
      handle_write_error!(response) unless [200, 201, 204].include?(response.status)

      case response.status
      when 201
        { status: "created", relation: response.body }
      when 204
        { status: "updated" }
      else
        { status: "success", relation: response.body }
      end
    end

    # POST /dossiers/{dossierId}/buysellbookings — Create a buy/sell booking.
    # The booking_data is wrapped in a BuySellBookingAndAttachmentRequest
    # (without attachments).
    #
    # Returns { status: "created" }.
    def create_buy_sell_booking(booking_data)
      ensure_dossier_connected!

      payload = {
        "buySellBookingServiceData" => booking_data
      }

      response = dossier_post("dossiers/#{@dossier_id}/buysellbookings", payload)
      handle_write_error!(response) unless [200, 201].include?(response.status)

      { status: "created" }
    end

    # POST /dossiers/{dossierId}/invoices — Create an invoice.
    #
    # Returns { status: "created" }.
    def create_invoice(invoice_data)
      ensure_dossier_connected!

      response = dossier_post("dossiers/#{@dossier_id}/invoices", invoice_data)
      handle_write_error!(response) unless [200, 201].include?(response.status)

      { status: "created" }
    end

    # POST /dossiers/{dossierId}/financialdiversbookings — Create a financial/divers booking.
    # The booking_data is wrapped in a FinancialDiversBookingAndAttachmentRequest
    # (without attachments).
    #
    # Returns { status: "created" }.
    def create_financial_divers_booking(booking_data)
      ensure_dossier_connected!

      payload = {
        "financialDiversBookingServiceData" => booking_data
      }

      response = dossier_post("dossiers/#{@dossier_id}/financialdiversbookings", payload)
      handle_write_error!(response) unless [200, 201].include?(response.status)

      { status: "created" }
    end

    private

    # Make a GET request with dossier token in header.
    def dossier_get(path)
      @connection.get(path) do |req|
        req.headers["dossierToken"] = @dossier_token
        yield req if block_given?
      end
    end

    # Make a POST request with dossier token in header.
    def dossier_post(path, body)
      @connection.post(path) do |req|
        req.headers["dossierToken"] = @dossier_token
        req.body = body
      end
    end

    # Make a PUT request with dossier token in header.
    def dossier_put(path, body)
      @connection.put(path) do |req|
        req.headers["dossierToken"] = @dossier_token
        req.body = body
      end
    end

    def ensure_authenticated!
      raise AuthenticationError, "Not authenticated. Call authenticate first." unless @auth_token
    end

    def ensure_dossier_connected!
      raise ApiError, "Not connected to a dossier. Call connect_dossier first." unless @dossier_token
    end

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
        # 404 often means "no data found" in Octopus, not a real error
        return nil
      else
        raise ApiError, "Octopus API error (HTTP #{response.status}): #{message}"
      end
    end

    # Error handler for write operations (POST/PUT).
    # Handles additional status codes specific to write operations:
    #   403 — Journal closed or in use by another user
    #   500 — Invalid data format
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
