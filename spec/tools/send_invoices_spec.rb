require "spec_helper"

RSpec.describe Tools::SendInvoices do
  describe ".call" do
    let(:valid_params) do
      {
        "bookyear_id" => 1,
        "journal_key" => "V1",
        "send_method" => "email"
      }
    end

    it "sends invoices successfully" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/invoices/send")
        .to_return(status: 200, body: "".to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("sent")
      expect(result[:message]).to include("sent")
    end

    it "sends correctly formatted data" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/invoices/send")
        .with { |req|
          body = JSON.parse(req.body)
          body["bookyearId"] == 1 &&
            body["journalKey"] == "V1" &&
            body["sendMethod"] == "email"
        }
        .to_return(status: 200, body: "".to_json, headers: { "Content-Type" => "application/json" })

      described_class.call(params: valid_params, context: octopus_context)

      expect(request_stub).to have_been_requested
    end

    it "returns error when configuration is missing" do
      result = described_class.call(
        params: valid_params,
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end

    it "returns error on API failure" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/invoices/send")
        .to_return(
          status: 400,
          body: { errorMessage: "Send failed" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:error]).to include("Octopus API error")
    end
  end
end
