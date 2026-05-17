require "spec_helper"

RSpec.describe Tools::GenerateInvoice do
  describe ".call" do
    let(:valid_params) do
      {
        "bookyear_id" => 1,
        "journal_key" => "V1",
        "document_sequence_nr" => 5
      }
    end

    let(:invoice_result) { { "invoiceData" => { "amount" => 121.0 }, "pdfContent" => nil } }

    it "generates an invoice successfully" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/invoices/generate")
        .with(query: hash_including("bookyearId" => "1", "journalKey" => "V1", "documentSequenceNr" => "5"))
        .to_return(status: 200, body: invoice_result.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:invoice]).to eq(invoice_result)
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
        params: valid_params,
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end
