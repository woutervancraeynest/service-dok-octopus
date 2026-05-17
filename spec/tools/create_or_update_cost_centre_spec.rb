require "spec_helper"

RSpec.describe Tools::CreateOrUpdateCostCentre do
  describe ".call" do
    let(:valid_params) do
      { "description" => "Marketing" }
    end

    it "saves a cost centre successfully (201 created)" do
      stub_octopus_full_auth
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/costcentres")
        .to_return(
          status: 201,
          body: { "costCentreKey" => { "id" => 1 } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("saved")
      expect(result[:message]).to include("saved")
    end

    it "saves a cost centre successfully (204 updated)" do
      stub_octopus_full_auth
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/costcentres")
        .to_return(status: 204, body: "", headers: {})

      result = described_class.call(
        params: valid_params.merge("cost_centre_id" => 1),
        context: octopus_context
      )

      expect(result[:status]).to eq("saved")
    end

    it "sends correctly formatted data with cost_centre_id" do
      stub_octopus_full_auth
      request_stub = stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/costcentres")
        .with { |req|
          body = JSON.parse(req.body)
          body["description"] == "Marketing" &&
            body["costCentreKey"]["id"] == 5 &&
            body["closed"] == false
        }
        .to_return(status: 204, body: "", headers: {})

      described_class.call(
        params: { "description" => "Marketing", "cost_centre_id" => 5, "closed" => false },
        context: octopus_context
      )

      expect(request_stub).to have_been_requested
    end

    it "returns error when description is missing" do
      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("description")
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
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/costcentres")
        .to_return(
          status: 400,
          body: { errorMessage: "Invalid cost centre" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:error]).to include("Octopus API error")
    end
  end
end
