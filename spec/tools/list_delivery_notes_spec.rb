require "spec_helper"

RSpec.describe Tools::ListDeliveryNotes do
  describe ".call" do
    let(:delivery_notes) do
      [
        {
          "journalKey" => "L1",
          "documentSequenceNr" => 1,
          "documentDate" => "2024-03-15",
          "deliveryLines" => [
            { "description" => "Widget", "count" => 5.0, "unitPrice" => 10.0 }
          ]
        }
      ]
    end

    it "returns delivery notes without filters" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/deliverynotes")
        .to_return(status: 200, body: delivery_notes.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:delivery_notes]).to eq(delivery_notes)
      expect(result[:total]).to eq(1)
    end

    it "passes filter parameters" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/deliverynotes")
        .with(query: { "bookyearKeyId" => "1", "journalKey" => "L1" })
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_key" => "L1" },
        context: octopus_context
      )

      expect(result[:delivery_notes]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "handles single delivery note response (non-array)" do
      stub_octopus_full_auth
      single_note = delivery_notes.first
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/deliverynotes")
        .to_return(status: 200, body: single_note.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:delivery_notes]).to be_an(Array)
      expect(result[:total]).to eq(1)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end
