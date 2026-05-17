require "spec_helper"

RSpec.describe Tools::UpdateFinancialDiversBooking do
  describe ".call" do
    let(:valid_params) do
      {
        "bookyear_id" => 1,
        "journal_key" => "F1",
        "document_sequence_nr" => 1,
        "period_nr" => 3,
        "document_date" => "2024-03-15",
        "booking_lines" => [
          { "type" => "A", "account_key" => 550000, "amount" => 1000.0 },
          { "type" => "C", "relation_id" => 10, "amount" => -1000.0 }
        ]
      }
    end

    it "updates a financial/divers booking successfully" do
      stub_octopus_full_auth
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/financialdiversbookings")
        .to_return(status: 204, body: "", headers: {})

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("updated")
      expect(result[:message]).to include("updated")
    end

    it "sends correctly formatted data" do
      stub_octopus_full_auth
      request_stub = stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/financialdiversbookings")
        .with { |req|
          body = JSON.parse(req.body)
          body["bookyearKey"]["id"] == 1 &&
            body["journalKey"] == "F1" &&
            body["bookingLines"].length == 2 &&
            body["bookingLines"][0]["type"] == "A" &&
            body["bookingLines"][0]["accountKey"] == 550000
        }
        .to_return(status: 204, body: "", headers: {})

      described_class.call(params: valid_params, context: octopus_context)

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

      expect(result[:error]).to include("booking_lines")
    end

    it "returns error when configuration is missing" do
      result = described_class.call(
        params: valid_params,
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end

    it "returns error on API failure" do
      stub_octopus_full_auth
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/financialdiversbookings")
        .to_return(
          status: 403,
          body: { errorMessage: "Journal is in use" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:error]).to include("Octopus API error")
    end
  end
end
