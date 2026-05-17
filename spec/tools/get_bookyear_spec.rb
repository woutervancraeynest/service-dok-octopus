require "spec_helper"

RSpec.describe Tools::GetBookyear do
  describe ".call" do
    let(:bookyear) do
      {
        "bookyearKey" => { "id" => 1 },
        "description" => "Boekjaar 2024",
        "startDate" => "2024-01-01",
        "endDate" => "2024-12-31",
        "closed" => false
      }
    end

    it "returns a bookyear by ID" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears/1")
        .to_return(status: 200, body: bookyear.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "bookyear_id" => 1 },
        context: octopus_context
      )

      expect(result[:bookyear]).to eq(bookyear)
    end

    it "returns error when bookyear_id is missing" do
      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("bookyear_id")
    end

    it "returns error when configuration is missing" do
      result = described_class.call(
        params: { "bookyear_id" => 1 },
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end
