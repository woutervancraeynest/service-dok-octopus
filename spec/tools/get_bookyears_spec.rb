require "spec_helper"

RSpec.describe Tools::GetBookyears do
  describe ".call" do
    let(:bookyears) do
      [
        {
          "bookyearKey" => { "id" => 1 },
          "bookyearDescription" => "2024",
          "startDate" => "2024-01-01",
          "endDate" => "2024-12-31",
          "closed" => false
        },
        {
          "bookyearKey" => { "id" => 2 },
          "bookyearDescription" => "2023",
          "startDate" => "2023-01-01",
          "endDate" => "2023-12-31",
          "closed" => true
        }
      ]
    end

    it "returns bookyears for the configured dossier" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears")
        .to_return(status: 200, body: bookyears.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:bookyears]).to eq(bookyears)
      expect(result[:total]).to eq(2)
    end

    it "returns empty list when no bookyears found" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:bookyears]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when dossier_id is missing" do
      result = described_class.call(params: {}, context: octopus_context("dossier_id" => ""))

      expect(result[:error]).to include("Missing dossier_id")
    end

    it "returns empty list when API returns nil (404)" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears")
        .to_return(status: 404, body: "", headers: {})

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:bookyears]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end
