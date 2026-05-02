require "spec_helper"

RSpec.describe Tools::CreateFinancialDiversBooking do
  describe ".call" do
    let(:valid_params) do
      {
        "bookyear_id" => 1,
        "journal_key" => "F1",
        "document_sequence_nr" => 1,
        "period_nr" => 3,
        "document_date" => "2024-03-15",
        "booking_lines" => [
          { "type" => "A", "account_key" => 550000, "amount" => 1000.0, "reference" => "Bank deposit" },
          { "type" => "C", "relation_id" => 10, "amount" => -1000.0, "reference" => "Payment client 10" }
        ]
      }
    end

    it "creates a financial booking successfully" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/financialdiversbookings")
        .to_return(status: 201, body: "", headers: {})

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("created")
      expect(result[:message]).to include("F1")
    end

    it "sends correctly formatted data with line types" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/financialdiversbookings")
        .with { |req|
          body = JSON.parse(req.body)
          data = body["financialDiversBookingServiceData"]
          lines = data["bookingLines"]
          data["bookyearKey"]["id"] == 1 &&
            data["journalKey"] == "F1" &&
            data["exchangeRate"] == 1.0 &&
            lines[0]["type"] == "A" &&
            lines[0]["accountKey"] == 550000 &&
            lines[0]["amount"] == 1000.0 &&
            lines[1]["type"] == "C" &&
            lines[1]["relationId"] == 10 &&
            lines[1]["amount"] == -1000.0
        }
        .to_return(status: 201, body: "", headers: {})

      described_class.call(params: valid_params, context: octopus_context)
      expect(request_stub).to have_been_requested
    end

    it "supports supplier lines with external_relation_id" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/financialdiversbookings")
        .with { |req|
          lines = JSON.parse(req.body)["financialDiversBookingServiceData"]["bookingLines"]
          lines[0]["type"] == "S" &&
            lines[0]["externalRelationId"] == 42
        }
        .to_return(status: 201, body: "", headers: {})

      params = valid_params.merge(
        "booking_lines" => [
          { "type" => "S", "external_relation_id" => 42, "amount" => -500.0 },
          { "type" => "A", "account_key" => 550000, "amount" => 500.0 }
        ]
      )

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

    it "returns error when booking_lines is empty" do
      params = valid_params.merge("booking_lines" => [])
      result = described_class.call(params: params, context: octopus_context)

      expect(result[:error]).to include("booking_line")
    end

    it "returns error when booking_lines is missing" do
      params = valid_params.tap { |p| p.delete("booking_lines") }
      result = described_class.call(params: params, context: octopus_context)

      expect(result[:error]).to include("booking_line")
    end

    it "returns error on journal closed (403)" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/financialdiversbookings")
        .to_return(
          status: 403,
          body: { errorMessage: "Journal is in use" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:error]).to include("Journal is closed")
    end

    it "supports cost centre on lines" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/financialdiversbookings")
        .with { |req|
          lines = JSON.parse(req.body)["financialDiversBookingServiceData"]["bookingLines"]
          lines[0]["costCentreKey"]["id"] == 5
        }
        .to_return(status: 201, body: "", headers: {})

      params = valid_params.merge(
        "booking_lines" => [
          { "type" => "A", "account_key" => 600000, "amount" => 100.0, "cost_centre_id" => 5 }
        ]
      )

      described_class.call(params: params, context: octopus_context)
      expect(request_stub).to have_been_requested
    end
  end
end
