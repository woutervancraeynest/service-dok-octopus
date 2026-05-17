require "spec_helper"

RSpec.describe Tools::GetJournalEntry do
  describe ".call" do
    let(:journal_entry) do
      {
        "journalKey" => "A1",
        "documentSequenceNr" => 5,
        "amount" => 121.0,
        "documentDate" => "2024-03-15"
      }
    end

    it "returns a buy journal entry (type A)" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears/1/journals/A/5")
        .to_return(status: 200, body: journal_entry.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_type" => "A", "sequence_number" => 5 },
        context: octopus_context
      )

      expect(result[:journal_entry]).to eq(journal_entry)
    end

    it "returns a sell journal entry (type V)" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears/1/journals/V/3")
        .to_return(status: 200, body: journal_entry.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_type" => "V", "sequence_number" => 3 },
        context: octopus_context
      )

      expect(result[:journal_entry]).to eq(journal_entry)
    end

    it "returns a financial journal entry (type F)" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears/1/journals/F/2")
        .to_return(status: 200, body: journal_entry.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_type" => "F", "sequence_number" => 2 },
        context: octopus_context
      )

      expect(result[:journal_entry]).to eq(journal_entry)
    end

    it "returns a divers journal entry (type D)" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears/1/journals/D/1")
        .to_return(status: 200, body: journal_entry.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_type" => "D", "sequence_number" => 1 },
        context: octopus_context
      )

      expect(result[:journal_entry]).to eq(journal_entry)
    end

    it "returns a delivery journal entry (type L)" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears/1/journals/L/4")
        .to_return(status: 200, body: journal_entry.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_type" => "L", "sequence_number" => 4 },
        context: octopus_context
      )

      expect(result[:journal_entry]).to eq(journal_entry)
    end

    it "accepts lowercase journal_type" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears/1/journals/A/5")
        .to_return(status: 200, body: journal_entry.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_type" => "a", "sequence_number" => 5 },
        context: octopus_context
      )

      expect(result[:journal_entry]).to eq(journal_entry)
    end

    it "returns error when required params are missing" do
      result = described_class.call(
        params: { "bookyear_id" => 1 },
        context: octopus_context
      )

      expect(result[:error]).to include("Missing required parameters")
    end

    it "returns error for invalid journal_type" do
      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_type" => "X", "sequence_number" => 1 },
        context: octopus_context
      )

      expect(result[:error]).to include("Invalid journal_type")
    end

    it "returns error when configuration is missing" do
      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_type" => "A", "sequence_number" => 5 },
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end
