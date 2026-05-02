require "spec_helper"

RSpec.describe Tools::ListAccounts do
  describe ".call" do
    let(:accounts) do
      [
        {
          "accountKey" => { "bookyearKey" => { "id" => 1 }, "id" => 600000 },
          "description" => { "description_NL" => "Aankopen handelsgoederen" }
        }
      ]
    end

    it "returns accounts for a bookyear" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/accounts")
        .with(query: { "bookyearId" => "1" })
        .to_return(status: 200, body: accounts.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "bookyear_id" => 1 },
        context: octopus_context
      )

      expect(result[:accounts]).to eq(accounts)
      expect(result[:total]).to eq(1)
    end

    it "returns error when bookyear_id is missing" do
      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("bookyear_id is required")
    end

    it "returns empty list when no accounts found" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/accounts")
        .with(query: { "bookyearId" => "1" })
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "bookyear_id" => 1 },
        context: octopus_context
      )

      expect(result[:accounts]).to eq([])
      expect(result[:total]).to eq(0)
    end
  end
end
