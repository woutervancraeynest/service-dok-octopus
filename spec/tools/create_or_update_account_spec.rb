require "spec_helper"

RSpec.describe Tools::CreateOrUpdateAccount do
  describe ".call" do
    let(:valid_params) do
      {
        "bookyear_id" => 1,
        "account_key" => 600000,
        "description1" => "Aankopen handelsgoederen"
      }
    end

    it "saves an account successfully (201 created)" do
      stub_octopus_full_auth
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/accounts")
        .to_return(
          status: 201,
          body: { "accountKey" => 600000 }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("saved")
      expect(result[:message]).to include("saved")
    end

    it "saves an account successfully (204 updated)" do
      stub_octopus_full_auth
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/accounts")
        .to_return(status: 204, body: "", headers: {})

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("saved")
    end

    it "sends correctly formatted data" do
      stub_octopus_full_auth
      request_stub = stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/accounts")
        .with { |req|
          body = JSON.parse(req.body)
          body["bookyearKey"]["id"] == 1 &&
            body["accountKey"] == 600000 &&
            body["description1"] == "Aankopen handelsgoederen"
        }
        .to_return(status: 201, body: {}.to_json, headers: { "Content-Type" => "application/json" })

      described_class.call(params: valid_params, context: octopus_context)

      expect(request_stub).to have_been_requested
    end

    it "returns error when required params are missing" do
      result = described_class.call(
        params: { "bookyear_id" => 1 },
        context: octopus_context
      )

      expect(result[:error]).to include("account_key")
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
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/accounts")
        .to_return(
          status: 400,
          body: { errorMessage: "Invalid account data" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:error]).to include("Octopus API error")
    end
  end
end
