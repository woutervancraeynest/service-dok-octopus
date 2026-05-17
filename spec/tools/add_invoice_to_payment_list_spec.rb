require "spec_helper"

RSpec.describe Tools::AddInvoiceToPaymentList do
  describe ".call" do
    let(:valid_params) do
      {
        "bookyear_id" => 1,
        "journal_key" => "A1",
        "document_sequence_nr" => 5
      }
    end

    it "adds an invoice to the payment list successfully" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bank/paymentlist")
        .to_return(status: 200, body: "".to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("added")
      expect(result[:message]).to include("payment list")
    end

    it "sends correctly formatted document data" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bank/paymentlist")
        .with { |req|
          body = JSON.parse(req.body)
          body["bookyearKey"]["id"] == 1 &&
            body["journalKey"] == "A1" &&
            body["documentSequenceNr"] == 5
        }
        .to_return(status: 200, body: "".to_json, headers: { "Content-Type" => "application/json" })

      described_class.call(params: valid_params, context: octopus_context)

      expect(request_stub).to have_been_requested
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
