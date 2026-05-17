require "spec_helper"

RSpec.describe Tools::UpdateDeliveryNote do
  describe ".call" do
    let(:valid_params) do
      {
        "bookyear_id" => 1,
        "journal_key" => "L1",
        "document_sequence_nr" => 1,
        "period_nr" => 3,
        "document_date" => "2024-03-15",
        "expiry_date" => "2024-04-15",
        "relation_id" => 10,
        "delivery_lines" => [
          { "description" => "Widget", "count" => 5.0, "unit_price" => 10.0, "vat_code" => "21" }
        ]
      }
    end

    it "updates a delivery note successfully" do
      stub_octopus_full_auth
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/deliverynotes")
        .to_return(status: 204, body: "", headers: {})

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("updated")
      expect(result[:message]).to include("updated")
    end

    it "sends correctly formatted data" do
      stub_octopus_full_auth
      request_stub = stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/deliverynotes")
        .with { |req|
          body = JSON.parse(req.body)
          body["bookyearKey"]["id"] == 1 &&
            body["journalKey"] == "L1" &&
            body["relationKey"]["id"] == 10 &&
            body["deliveryLines"][0]["description"] == "Widget"
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

    it "returns error when delivery_lines is empty" do
      params = valid_params.merge("delivery_lines" => [])
      result = described_class.call(params: params, context: octopus_context)

      expect(result[:error]).to include("delivery_line")
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
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/deliverynotes")
        .to_return(
          status: 403,
          body: { errorMessage: "Journal closed" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:error]).to include("Octopus API error")
    end
  end
end
