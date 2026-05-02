require "spec_helper"

RSpec.describe Tools::ListRelations do
  describe ".call" do
    let(:relations) do
      [
        { "name" => "Acme BV", "client" => true, "supplier" => false, "vatNr" => "BE0111222333" },
        { "name" => "Globex NV", "client" => false, "supplier" => true, "vatNr" => "BE0444555666" }
      ]
    end

    it "returns relations for the configured dossier" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .to_return(status: 200, body: relations.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:relations]).to eq(relations)
      expect(result[:total]).to eq(2)
    end

    it "returns empty list when no relations found" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:relations]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns empty list when API returns nil (404)" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .to_return(status: 404, body: "", headers: {})

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:relations]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end
