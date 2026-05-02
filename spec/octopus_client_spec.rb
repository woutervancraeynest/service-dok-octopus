require "spec_helper"

RSpec.describe OctopusClient::Client do
  let(:client) do
    OctopusClient::Client.new(
      user: "testuser",
      password: "testpass",
      software_house_id: "test-uuid-1234"
    )
  end

  describe ".new" do
    it "raises ConfigurationError when user is missing" do
      expect {
        OctopusClient::Client.new(user: "", password: "pass", software_house_id: "uuid")
      }.to raise_error(OctopusClient::ConfigurationError, /user is required/)
    end

    it "raises ConfigurationError when password is missing" do
      expect {
        OctopusClient::Client.new(user: "user", password: nil, software_house_id: "uuid")
      }.to raise_error(OctopusClient::ConfigurationError, /password is required/)
    end

    it "raises ConfigurationError when software_house_id is missing" do
      expect {
        OctopusClient::Client.new(user: "user", password: "pass", software_house_id: "")
      }.to raise_error(OctopusClient::ConfigurationError, /Software House ID is required/)
    end
  end

  describe "#authenticate" do
    it "authenticates successfully and stores the token" do
      stub_octopus_auth(token: "my-auth-token")

      token = client.authenticate

      expect(token).to eq("my-auth-token")
      expect(client.auth_token).to eq("my-auth-token")
    end

    it "sends correct headers and body" do
      auth_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/authentication")
        .with(
          headers: { "softwareHouseUuid" => "test-uuid-1234" },
          body: { user: "testuser", password: "testpass" }.to_json
        )
        .to_return(
          status: 200,
          body: { token: "tok" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      client.authenticate

      expect(auth_stub).to have_been_requested
    end

    it "raises AuthenticationError on 401" do
      stub_request(:post, "#{OctopusClient::BASE_URL}/authentication")
        .to_return(
          status: 401,
          body: { errorMessage: "Bad credentials" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.authenticate }.to raise_error(
        OctopusClient::AuthenticationError, /Invalid credentials.*Bad credentials/
      )
    end

    it "raises AuthenticationError on non-401 error (e.g. 500)" do
      stub_request(:post, "#{OctopusClient::BASE_URL}/authentication")
        .to_return(
          status: 500,
          body: { errorMessage: "Internal error" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.authenticate }.to raise_error(
        OctopusClient::AuthenticationError, /Authentication error \(HTTP 500\)/
      )
    end

    it "raises AuthenticationError with generic message when body is not JSON" do
      stub_request(:post, "#{OctopusClient::BASE_URL}/authentication")
        .to_return(
          status: 401,
          body: "Unauthorized",
          headers: { "Content-Type" => "text/plain" }
        )

      expect { client.authenticate }.to raise_error(
        OctopusClient::AuthenticationError, /Invalid credentials.*Authentication failed/
      )
    end

    it "raises AuthenticationError when no token in response" do
      stub_request(:post, "#{OctopusClient::BASE_URL}/authentication")
        .to_return(
          status: 200,
          body: {}.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.authenticate }.to raise_error(
        OctopusClient::AuthenticationError, /No token received/
      )
    end
  end

  describe "#connect_dossier" do
    before { stub_octopus_auth(token: "auth-tok") && client.authenticate }

    it "connects successfully and stores the dossier token" do
      stub_octopus_connect_dossier(dossier_token: "dossier-tok")

      token = client.connect_dossier(42)

      expect(token).to eq("dossier-tok")
      expect(client.dossier_token).to eq("dossier-tok")
      expect(client.dossier_id).to eq(42)
    end

    it "sends the auth token in headers" do
      connect_stub = stub_request(:post, /#{Regexp.escape(OctopusClient::BASE_URL)}\/dossiers/)
        .with(headers: { "Token" => "auth-tok" })
        .to_return(
          status: 200,
          body: { Dossiertoken: "dt" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      client.connect_dossier(42)

      expect(connect_stub).to have_been_requested
    end

    it "raises AuthenticationError when not authenticated" do
      unauthenticated_client = OctopusClient::Client.new(
        user: "user", password: "pass", software_house_id: "uuid"
      )

      expect { unauthenticated_client.connect_dossier(42) }.to raise_error(
        OctopusClient::AuthenticationError, /Not authenticated/
      )
    end

    it "raises ApiError on failure" do
      stub_octopus_auth(token: "auth-tok")
      client.authenticate

      stub_request(:post, /#{Regexp.escape(OctopusClient::BASE_URL)}\/dossiers/)
        .to_return(
          status: 400,
          body: { errorMessage: "Invalid dossier" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.connect_dossier(999) }.to raise_error(
        OctopusClient::ApiError, /Invalid dossier/
      )
    end

    it "raises ApiError when no dossier token in response" do
      stub_octopus_connect_dossier
      # Override the stub to return empty body
      stub_request(:post, /#{Regexp.escape(OctopusClient::BASE_URL)}\/dossiers/)
        .to_return(
          status: 200,
          body: {}.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.connect_dossier(42) }.to raise_error(
        OctopusClient::ApiError, /No dossier token received/
      )
    end

    it "accepts lowercase dossiertoken key in response" do
      stub_request(:post, /#{Regexp.escape(OctopusClient::BASE_URL)}\/dossiers/)
        .to_return(
          status: 200,
          body: { "dossiertoken" => "lowercase-tok" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      token = client.connect_dossier(42)
      expect(token).to eq("lowercase-tok")
    end

    it "raises AuthenticationError on 401 (token expired)" do
      stub_request(:post, /#{Regexp.escape(OctopusClient::BASE_URL)}\/dossiers/)
        .to_return(
          status: 401,
          body: { errorMessage: "Token expired" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.connect_dossier(42) }.to raise_error(
        OctopusClient::AuthenticationError, /Token expired/
      )
    end
  end

  describe "#with_dossier" do
    it "authenticates, connects to dossier, and yields client" do
      stub_octopus_full_auth

      result = client.with_dossier(42) do |c|
        expect(c.auth_token).to eq("test-auth-token")
        expect(c.dossier_token).to eq("test-dossier-token")
        "done"
      end

      expect(result).to eq("done")
    end
  end

  describe "#list_dossiers" do
    before { stub_octopus_auth && client.authenticate }

    it "returns list of dossiers" do
      dossiers = [
        { "dossierKey" => { "id" => 1 }, "dossierDescription" => "Test BV" },
        { "dossierKey" => { "id" => 2 }, "dossierDescription" => "Other NV" }
      ]

      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers")
        .to_return(
          status: 200,
          body: dossiers.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.list_dossiers
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result[0]["dossierDescription"]).to eq("Test BV")
    end

    it "raises AuthenticationError when not authenticated" do
      unauthenticated = OctopusClient::Client.new(
        user: "user", password: "pass", software_house_id: "uuid"
      )

      expect { unauthenticated.list_dossiers }.to raise_error(
        OctopusClient::AuthenticationError, /Not authenticated/
      )
    end
  end

  describe "#get_bookyears" do
    it "returns bookyears for the connected dossier" do
      stub_octopus_full_auth && client.with_dossier(42) {}

      bookyears = [
        { "bookyearKey" => { "id" => 1 }, "bookyearDescription" => "2024" }
      ]

      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears")
        .to_return(
          status: 200,
          body: bookyears.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.get_bookyears
      expect(result).to be_an(Array)
      expect(result[0]["bookyearDescription"]).to eq("2024")
    end

    it "raises ApiError when not connected to a dossier" do
      stub_octopus_auth && client.authenticate

      expect { client.get_bookyears }.to raise_error(
        OctopusClient::ApiError, /Not connected to a dossier/
      )
    end

    it "returns nil on 404 (no data found)" do
      stub_octopus_full_auth && client.with_dossier(42) {}

      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears")
        .to_return(status: 404, body: "", headers: {})

      result = client.get_bookyears
      expect(result).to be_nil
    end
  end

  describe "#get_relations" do
    before { stub_octopus_full_auth && client.with_dossier(42) {} }

    it "returns relations for the connected dossier" do
      relations = [
        { "name" => "Acme BV", "client" => true, "supplier" => false }
      ]

      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .to_return(
          status: 200,
          body: relations.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.get_relations
      expect(result).to be_an(Array)
      expect(result[0]["name"]).to eq("Acme BV")
    end
  end

  describe "#get_accounts" do
    before { stub_octopus_full_auth && client.with_dossier(42) {} }

    it "returns accounts for a bookyear" do
      accounts = [
        { "accountKey" => { "id" => 600000 }, "description" => { "description_NL" => "Aankopen" } }
      ]

      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/accounts")
        .with(query: { "bookyearId" => "1" })
        .to_return(
          status: 200,
          body: accounts.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.get_accounts(bookyear_id: 1)
      expect(result).to be_an(Array)
      expect(result[0]["accountKey"]["id"]).to eq(600000)
    end
  end

  describe "#get_journals" do
    before { stub_octopus_full_auth && client.with_dossier(42) {} }

    it "returns journals for a bookyear" do
      journals = [
        { "journalKey" => "A1", "name" => "Aankoopdagboek" }
      ]

      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears/1/journals")
        .to_return(
          status: 200,
          body: journals.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.get_journals(bookyear_id: 1)
      expect(result).to be_an(Array)
      expect(result[0]["journalKey"]).to eq("A1")
    end
  end

  describe "#get_buy_sell_bookings" do
    before { stub_octopus_full_auth && client.with_dossier(42) {} }

    it "returns buy/sell bookings without filters" do
      bookings = [{ "journalKey" => "A1", "amount" => 100.0 }]

      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/buysellbookings")
        .to_return(
          status: 200,
          body: bookings.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.get_buy_sell_bookings
      expect(result).to be_an(Array)
      expect(result[0]["amount"]).to eq(100.0)
    end

    it "passes filter parameters" do
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/buysellbookings")
        .with(query: { "bookyearKeyId" => "1", "journalKey" => "V1" })
        .to_return(
          status: 200,
          body: [].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      client.get_buy_sell_bookings(bookyear_key_id: 1, journal_key: "V1")
    end
  end

  describe "#get_invoices" do
    before { stub_octopus_full_auth && client.with_dossier(42) {} }

    it "returns invoices" do
      invoices = [{ "journalKey" => "V1", "documentSequenceNr" => 1 }]

      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/invoices")
        .to_return(
          status: 200,
          body: invoices.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.get_invoices
      expect(result).to be_an(Array)
      expect(result[0]["journalKey"]).to eq("V1")
    end
  end

  # --- Write endpoints ---

  describe "#create_or_update_relation" do
    before { stub_octopus_full_auth && client.with_dossier(42) {} }

    let(:relation_data) { { "name" => "Test BV", "currencyCode" => "EUR" } }

    it "creates a new relation (201)" do
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .to_return(
          status: 201,
          body: relation_data.merge("relationIdentificationServiceData" => { "relationKey" => { "id" => 99 } }).to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.create_or_update_relation(relation_data)
      expect(result[:status]).to eq("created")
      expect(result[:relation]).to be_a(Hash)
    end

    it "updates an existing relation (204)" do
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .to_return(status: 204, body: "", headers: {})

      result = client.create_or_update_relation(relation_data)
      expect(result[:status]).to eq("updated")
    end

    it "handles 200 success as fallback status" do
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .to_return(
          status: 200,
          body: relation_data.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.create_or_update_relation(relation_data)
      expect(result[:status]).to eq("success")
    end

    it "raises ApiError on 400" do
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .to_return(
          status: 400,
          body: { errorMessage: "Missing currency" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.create_or_update_relation(relation_data) }.to raise_error(
        OctopusClient::ApiError, /Invalid or missing parameters/
      )
    end

    it "raises AuthenticationError on 401 (token expired during write)" do
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .to_return(
          status: 401,
          body: { errorMessage: "Token expired" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.create_or_update_relation(relation_data) }.to raise_error(
        OctopusClient::AuthenticationError, /Token expired/
      )
    end

    it "raises ApiError on 403 (journal closed)" do
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .to_return(
          status: 403,
          body: { errorMessage: "Access denied" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.create_or_update_relation(relation_data) }.to raise_error(
        OctopusClient::ApiError, /Journal is closed/
      )
    end

    it "raises ApiError when response body is not JSON (e.g. HTML 502)" do
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .to_return(
          status: 502,
          body: "<html>Bad Gateway</html>",
          headers: { "Content-Type" => "text/html" }
        )

      expect { client.create_or_update_relation(relation_data) }.to raise_error(
        OctopusClient::ApiError, /HTTP 502.*Write operation failed/
      )
    end

    it "raises ApiError when not connected to dossier" do
      unauthenticated = OctopusClient::Client.new(
        user: "user", password: "pass", software_house_id: "uuid"
      )

      expect { unauthenticated.create_or_update_relation(relation_data) }.to raise_error(
        OctopusClient::ApiError, /Not connected to a dossier/
      )
    end
  end

  describe "#create_buy_sell_booking" do
    before { stub_octopus_full_auth && client.with_dossier(42) {} }

    let(:booking_data) do
      {
        "bookyearKey" => { "id" => 1 },
        "journalKey" => "A1",
        "documentSequenceNr" => 1,
        "amount" => 121.0
      }
    end

    it "creates a booking successfully (201)" do
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/buysellbookings")
        .to_return(status: 201, body: "", headers: {})

      result = client.create_buy_sell_booking(booking_data)
      expect(result[:status]).to eq("created")
    end

    it "sends the booking wrapped in BuySellBookingAndAttachmentRequest" do
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/buysellbookings")
        .with(body: { "buySellBookingServiceData" => booking_data }.to_json)
        .to_return(status: 201, body: "", headers: {})

      client.create_buy_sell_booking(booking_data)
      expect(request_stub).to have_been_requested
    end

    it "raises ApiError on 403 (journal closed)" do
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/buysellbookings")
        .to_return(
          status: 403,
          body: { errorMessage: "Journal closed" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.create_buy_sell_booking(booking_data) }.to raise_error(
        OctopusClient::ApiError, /Journal is closed/
      )
    end

    it "raises ApiError on 500 (invalid data)" do
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/buysellbookings")
        .to_return(status: 500, body: "", headers: {})

      expect { client.create_buy_sell_booking(booking_data) }.to raise_error(
        OctopusClient::ApiError, /Invalid data format/
      )
    end
  end

  describe "#create_invoice" do
    before { stub_octopus_full_auth && client.with_dossier(42) {} }

    let(:invoice_data) do
      {
        "bookyearKey" => { "id" => 1 },
        "journalKey" => "V1",
        "documentSequenceNr" => 1
      }
    end

    it "creates an invoice successfully (201)" do
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/invoices")
        .to_return(status: 201, body: "", headers: {})

      result = client.create_invoice(invoice_data)
      expect(result[:status]).to eq("created")
    end

    it "sends invoice data directly (not wrapped)" do
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/invoices")
        .with(body: invoice_data.to_json)
        .to_return(status: 201, body: "", headers: {})

      client.create_invoice(invoice_data)
      expect(request_stub).to have_been_requested
    end
  end

  describe "#create_financial_divers_booking" do
    before { stub_octopus_full_auth && client.with_dossier(42) {} }

    let(:booking_data) do
      {
        "bookyearKey" => { "id" => 1 },
        "journalKey" => "F1",
        "documentSequenceNr" => 1
      }
    end

    it "creates a financial/divers booking successfully (201)" do
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/financialdiversbookings")
        .to_return(status: 201, body: "", headers: {})

      result = client.create_financial_divers_booking(booking_data)
      expect(result[:status]).to eq("created")
    end

    it "sends booking wrapped in FinancialDiversBookingAndAttachmentRequest" do
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/financialdiversbookings")
        .with(body: { "financialDiversBookingServiceData" => booking_data }.to_json)
        .to_return(status: 201, body: "", headers: {})

      client.create_financial_divers_booking(booking_data)
      expect(request_stub).to have_been_requested
    end
  end

  # --- Error handler edge cases ---

  describe "error handlers" do
    before { stub_octopus_full_auth && client.with_dossier(42) {} }

    describe "handle_api_error! — non-Hash body" do
      it "uses generic message when API returns non-JSON body" do
        stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
          .to_return(
            status: 500,
            body: "<html>Server Error</html>",
            headers: { "Content-Type" => "text/html" }
          )

        expect { client.get_relations }.to raise_error(
          OctopusClient::ApiError, /API request failed/
        )
      end
    end

    describe "handle_api_error! — generic status code" do
      it "raises ApiError with HTTP status for unknown error codes" do
        stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
          .to_return(
            status: 422,
            body: { errorMessage: "Unprocessable" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect { client.get_relations }.to raise_error(
          OctopusClient::ApiError, /HTTP 422.*Unprocessable/
        )
      end
    end

    describe "handle_write_error! — non-Hash body" do
      it "uses generic message when write response is not JSON" do
        stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/buysellbookings")
          .to_return(
            status: 400,
            body: "Bad Request",
            headers: { "Content-Type" => "text/plain" }
          )

        expect { client.create_buy_sell_booking({}) }.to raise_error(
          OctopusClient::ApiError, /Invalid or missing parameters.*Write operation failed/
        )
      end
    end
  end

  # --- Faraday::Error (network failures) ---

  describe "network error handling" do
    it "raises Faraday::Error on connection timeout" do
      stub_request(:post, "#{OctopusClient::BASE_URL}/authentication")
        .to_timeout

      expect { client.authenticate }.to raise_error(Faraday::ConnectionFailed)
    end

    it "raises Faraday::Error on DNS resolution failure" do
      stub_request(:post, "#{OctopusClient::BASE_URL}/authentication")
        .to_raise(Faraday::ConnectionFailed.new("DNS resolution failed"))

      expect { client.authenticate }.to raise_error(Faraday::ConnectionFailed)
    end
  end
end
