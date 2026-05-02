require "spec_helper"

RSpec.describe Tools::ListJournals do
  describe ".call" do
    let(:journals) do
      [
        { "journalKey" => "A1", "name" => "Aankoopdagboek", "closed" => false },
        { "journalKey" => "V1", "name" => "Verkoopdagboek", "closed" => false },
        { "journalKey" => "F1", "name" => "Financieel dagboek", "closed" => false }
      ]
    end

    it "returns journals for a bookyear" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears/1/journals")
        .to_return(status: 200, body: journals.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "bookyear_id" => 1 },
        context: octopus_context
      )

      expect(result[:journals]).to eq(journals)
      expect(result[:total]).to eq(3)
    end

    it "returns error when bookyear_id is missing" do
      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("bookyear_id is required")
    end
  end
end
