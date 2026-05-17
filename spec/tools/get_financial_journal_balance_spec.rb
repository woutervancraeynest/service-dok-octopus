require "spec_helper"

RSpec.describe Tools::GetFinancialJournalBalance do
  describe ".call" do
    let(:balance) do
      {
        "journalKey" => "F1",
        "balance" => 5000.0,
        "debit" => 10000.0,
        "credit" => 5000.0
      }
    end

    it "returns journal balance" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears/1/journals/F1")
        .to_return(status: 200, body: balance.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_key" => "F1" },
        context: octopus_context
      )

      expect(result[:balance]).to eq(balance)
    end

    it "returns error when required params are missing" do
      result = described_class.call(
        params: { "bookyear_id" => 1 },
        context: octopus_context
      )

      expect(result[:error]).to include("Missing required parameters")
    end

    it "returns error when configuration is missing" do
      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_key" => "F1" },
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end
