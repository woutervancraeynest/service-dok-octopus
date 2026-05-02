require "spec_helper"

RSpec.describe Tools::ListDossiers do
  describe ".call" do
    let(:dossiers) do
      [
        { "dossierKey" => { "id" => 1 }, "dossierDescription" => "Bedrijf A BV", "vatNr" => "BE0123456789" },
        { "dossierKey" => { "id" => 2 }, "dossierDescription" => "Bedrijf B NV", "vatNr" => "BE9876543210" }
      ]
    end

    it "returns list of dossiers" do
      stub_octopus_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers")
        .to_return(status: 200, body: dossiers.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:dossiers]).to eq(dossiers)
      expect(result[:total]).to eq(2)
    end

    it "returns empty list when no dossiers found" do
      stub_octopus_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:dossiers]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end

    it "returns error on authentication failure" do
      stub_request(:post, "#{OctopusClient::BASE_URL}/authentication")
        .to_return(status: 401, body: { errorMessage: "Bad credentials" }.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("Authentication failed")
    end
  end
end
