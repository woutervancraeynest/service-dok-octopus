require "spec_helper"

RSpec.describe Tools::ListInvoices do
  describe ".call" do
    let(:invoices) do
      [
        {
          "journalKey" => "V1",
          "documentSequenceNr" => 1,
          "documentDate" => "2024-03-15",
          "currencyCode" => "EUR",
          "invoiceLines" => [
            { "description" => "Consulting", "count" => 10.0, "unitPrice" => 100.0 }
          ]
        }
      ]
    end

    it "returns invoices without filters" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/invoices")
        .to_return(status: 200, body: invoices.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:invoices]).to eq(invoices)
      expect(result[:total]).to eq(1)
    end

    it "passes filter parameters" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/invoices")
        .with(query: { "bookyearKeyId" => "1", "journalKey" => "V1", "documentSequenceNr" => "5" })
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_key" => "V1", "document_sequence_nr" => 5 },
        context: octopus_context
      )

      expect(result[:invoices]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end

    it "handles single invoice response (non-array)" do
      stub_octopus_full_auth
      single_invoice = invoices.first
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/invoices")
        .to_return(status: 200, body: single_invoice.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:invoices]).to be_an(Array)
      expect(result[:total]).to eq(1)
    end
  end
end
