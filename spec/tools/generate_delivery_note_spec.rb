require "spec_helper"

RSpec.describe Tools::GenerateDeliveryNote do
  describe ".call" do
    let(:valid_params) do
      {
        "bookyear_id" => 1,
        "journal_key" => "L1",
        "document_sequence_nr" => 3
      }
    end

    let(:delivery_note_result) { { "deliveryNoteData" => { "lines" => [] }, "pdfContent" => nil } }

    it "generates a delivery note successfully" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/deliverynotes/generate")
        .with(query: hash_including("bookyearId" => "1", "journalKey" => "L1", "documentSequenceNr" => "3"))
        .to_return(status: 200, body: delivery_note_result.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:delivery_note]).to eq(delivery_note_result)
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
