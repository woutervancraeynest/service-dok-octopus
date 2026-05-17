require "spec_helper"

RSpec.describe Tools::AddFreePayment do
  describe ".call" do
    let(:valid_params) do
      {
        "amount" => 500.0,
        "reference" => "PAY-001",
        "iban" => "BE68539007547034",
        "beneficiary_name" => "Acme BV"
      }
    end

    it "adds a free payment successfully" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bank/paymentlist/freepayment")
        .to_return(status: 200, body: "".to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("added")
      expect(result[:message]).to include("Free payment added")
    end

    it "sends correctly formatted data" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bank/paymentlist/freepayment")
        .with { |req|
          body = JSON.parse(req.body)
          body["amount"] == 500.0 &&
            body["reference"] == "PAY-001" &&
            body["iban"] == "BE68539007547034" &&
            body["beneficiaryName"] == "Acme BV"
        }
        .to_return(status: 200, body: "".to_json, headers: { "Content-Type" => "application/json" })

      described_class.call(params: valid_params, context: octopus_context)

      expect(request_stub).to have_been_requested
    end

    it "supports relation_id" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bank/paymentlist/freepayment")
        .with { |req|
          body = JSON.parse(req.body)
          body["relationKey"]["id"] == 10
        }
        .to_return(status: 200, body: "".to_json, headers: { "Content-Type" => "application/json" })

      described_class.call(
        params: valid_params.merge("relation_id" => 10),
        context: octopus_context
      )

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
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bank/paymentlist/freepayment")
        .to_return(
          status: 400,
          body: { errorMessage: "Invalid payment" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:error]).to include("Octopus API error")
    end
  end
end
