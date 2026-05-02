require "spec_helper"

RSpec.describe Tools::CreateBuySellBooking do
  describe ".call" do
    let(:valid_params) do
      {
        "bookyear_id" => 1,
        "journal_key" => "A1",
        "document_sequence_nr" => 5,
        "period_nr" => 3,
        "document_date" => "2024-03-15",
        "expiry_date" => "2024-04-15",
        "amount" => 121.0,
        "relation_id" => 10,
        "reference" => "INV-2024-001",
        "booking_lines" => [
          { "account_key" => 600000, "base_amount" => 100.0, "vat_code" => "21", "vat_amount" => 21.0 }
        ]
      }
    end

    it "creates a booking successfully" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/buysellbookings")
        .to_return(status: 201, body: "", headers: {})

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("created")
      expect(result[:message]).to include("A1")
    end

    it "sends correctly formatted data to Octopus" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/buysellbookings")
        .with { |req|
          body = JSON.parse(req.body)
          data = body["buySellBookingServiceData"]
          data["bookyearKey"]["id"] == 1 &&
            data["journalKey"] == "A1" &&
            data["documentSequenceNr"] == 5 &&
            data["amount"] == 121.0 &&
            data["currencyCode"] == "EUR" &&
            data["exchangeRate"] == 1.0 &&
            data["relationIdentificationServiceData"]["relationKey"]["id"] == 10 &&
            data["reference"] == "INV-2024-001" &&
            data["bookingLines"][0]["accountKey"] == 600000 &&
            data["bookingLines"][0]["vatCodeKey"] == "21"
        }
        .to_return(status: 201, body: "", headers: {})

      described_class.call(params: valid_params, context: octopus_context)
      expect(request_stub).to have_been_requested
    end

    it "supports external_relation_id instead of relation_id" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/buysellbookings")
        .with { |req|
          data = JSON.parse(req.body)["buySellBookingServiceData"]
          data["relationIdentificationServiceData"]["externalRelationId"] == 42
        }
        .to_return(status: 201, body: "", headers: {})

      params = valid_params.merge("external_relation_id" => 42).tap { |p| p.delete("relation_id") }
      described_class.call(params: params, context: octopus_context)
      expect(request_stub).to have_been_requested
    end

    it "returns error when required params are missing" do
      result = described_class.call(
        params: { "bookyear_id" => 1 },
        context: octopus_context
      )

      expect(result[:error]).to include("Missing required parameters")
    end

    it "returns error when neither relation_id nor external_relation_id is given" do
      params = valid_params.tap { |p| p.delete("relation_id") }
      result = described_class.call(params: params, context: octopus_context)

      expect(result[:error]).to include("relation_id")
    end

    it "works without booking_lines" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/buysellbookings")
        .to_return(status: 201, body: "", headers: {})

      params = valid_params.tap { |p| p.delete("booking_lines") }
      result = described_class.call(params: params, context: octopus_context)

      expect(result[:status]).to eq("created")
    end

    it "returns error on journal closed (403)" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/buysellbookings")
        .to_return(
          status: 403,
          body: { errorMessage: "Journal closed" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:error]).to include("Journal is closed")
    end

    it "maps optional fields: comment, order_reference, custom currency" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/buysellbookings")
        .with { |req|
          data = JSON.parse(req.body)["buySellBookingServiceData"]
          data["comment"] == "Test comment" &&
            data["orderReference"] == "PO-123" &&
            data["currencyCode"] == "USD" &&
            data["exchangeRate"] == 1.08
        }
        .to_return(status: 201, body: "", headers: {})

      params = valid_params.merge(
        "comment" => "Test comment",
        "order_reference" => "PO-123",
        "currency_code" => "USD",
        "exchange_rate" => 1.08
      )

      described_class.call(params: params, context: octopus_context)
      expect(request_stub).to have_been_requested
    end

    it "maps booking line cost_centre_id and comment" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/buysellbookings")
        .with { |req|
          lines = JSON.parse(req.body)["buySellBookingServiceData"]["bookingLines"]
          lines[0]["costCentreKey"]["id"] == 5 &&
            lines[0]["comment"] == "Line note"
        }
        .to_return(status: 201, body: "", headers: {})

      params = valid_params.merge(
        "booking_lines" => [
          { "account_key" => 600000, "base_amount" => 100.0, "vat_code" => "21",
            "vat_amount" => 21.0, "comment" => "Line note", "cost_centre_id" => 5 }
        ]
      )

      described_class.call(params: params, context: octopus_context)
      expect(request_stub).to have_been_requested
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: valid_params, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end
