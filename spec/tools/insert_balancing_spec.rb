require "spec_helper"

RSpec.describe Tools::InsertBalancing do
  describe ".call" do
    let(:valid_params) do
      {
        "amount" => 100.0,
        "balancing_date" => "2026-05-06",
        "document_keys" => [
          { "bookyear_id" => 10, "journal_key" => "F1", "document_sequence_nr" => 68 },
          { "bookyear_id" => 10, "journal_key" => "A1", "document_sequence_nr" => 111 }
        ]
      }
    end

    it "inserts a balancing successfully" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/balancings")
        .to_return(status: 201, body: "".to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("created")
      expect(result[:message]).to include("inserted")
    end

    it "sends correctly formatted data to Octopus" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/balancings")
        .with { |req|
          body = JSON.parse(req.body)
          body["amount"] == 100.0 &&
            body["balancingDate"] == "2026-05-06" &&
            body["documentKeys"].length == 2 &&
            body["documentKeys"][0]["bookyearKey"]["id"] == 10 &&
            body["documentKeys"][0]["journalKey"] == "F1" &&
            body["documentKeys"][0]["documentSequenceNr"] == 68
        }
        .to_return(status: 201, body: "".to_json, headers: { "Content-Type" => "application/json" })

      described_class.call(params: valid_params, context: octopus_context)

      expect(request_stub).to have_been_requested
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
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/balancings")
        .to_return(
          status: 400,
          body: { errorMessage: "Invalid balancing data" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:error]).to include("Octopus API error")
    end
  end
end
