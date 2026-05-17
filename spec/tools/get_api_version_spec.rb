require "spec_helper"

RSpec.describe Tools::GetApiVersion do
  describe ".call" do
    it "returns the API version" do
      stub_octopus_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/about/version")
        .to_return(status: 200, body: "1.2.3".to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:version]).to eq("1.2.3")
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end
