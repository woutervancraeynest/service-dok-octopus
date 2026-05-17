require "spec_helper"

RSpec.describe Tools::CreateOrUpdateProduct do
  describe ".call" do
    let(:valid_params) do
      { "description" => "Widget A" }
    end

    it "saves a product successfully (201 created)" do
      stub_octopus_full_auth
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/products")
        .to_return(
          status: 201,
          body: { "productKey" => { "id" => 1 } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("saved")
      expect(result[:message]).to include("saved")
    end

    it "saves a product successfully (204 updated)" do
      stub_octopus_full_auth
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/products")
        .to_return(status: 204, body: "", headers: {})

      result = described_class.call(
        params: valid_params.merge("product_id" => 1),
        context: octopus_context
      )

      expect(result[:status]).to eq("saved")
    end

    it "sends correctly formatted data with optional fields" do
      stub_octopus_full_auth
      request_stub = stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/products")
        .with { |req|
          body = JSON.parse(req.body)
          body["description"] == "Widget A" &&
            body["productKey"]["id"] == 5 &&
            body["unitPrice"] == 25.0 &&
            body["unit"] == "pcs" &&
            body["vatCode"] == "21" &&
            body["bookingAccountNr"] == 700000 &&
            body["productGroupKey"]["id"] == 2
        }
        .to_return(status: 204, body: "", headers: {})

      described_class.call(
        params: {
          "description" => "Widget A",
          "product_id" => 5,
          "unit_price" => 25.0,
          "unit" => "pcs",
          "vat_code" => "21",
          "booking_account_nr" => 700000,
          "product_group_id" => 2
        },
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
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/products")
        .to_return(
          status: 400,
          body: { errorMessage: "Invalid product" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:error]).to include("Octopus API error")
    end
  end
end
