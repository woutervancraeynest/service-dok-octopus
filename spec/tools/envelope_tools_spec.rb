require "spec_helper"

# ─── CreateEnvelope ──────────────────────────────────────────────────────────
RSpec.describe Tools::CreateEnvelope do
  describe ".call" do
    let(:valid_params) do
      {
        "description" => "Payment batch Jan",
        "execution_date" => "2024-01-31",
        "debit_account_iban" => "BE68539007547034"
      }
    end

    it "creates an envelope successfully" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bank/enveloppes")
        .to_return(
          status: 200,
          body: { "enveloppeKeyId" => 1 }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("created")
      expect(result[:message]).to include("created")
    end

    it "sends correctly formatted data" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bank/enveloppes")
        .with { |req|
          body = JSON.parse(req.body)
          body["description"] == "Payment batch Jan" &&
            body["executionDate"] == "2024-01-31" &&
            body["debitAccountIban"] == "BE68539007547034"
        }
        .to_return(status: 200, body: {}.to_json, headers: { "Content-Type" => "application/json" })

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
  end
end

# ─── UpdateEnvelope ──────────────────────────────────────────────────────────
RSpec.describe Tools::UpdateEnvelope do
  describe ".call" do
    let(:valid_params) do
      {
        "envelope_key_id" => 5,
        "description" => "Updated batch",
        "execution_date" => "2024-02-15"
      }
    end

    it "updates an envelope successfully" do
      stub_octopus_full_auth
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/bank/enveloppes/5")
        .to_return(status: 204, body: "", headers: {})

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("updated")
      expect(result[:message]).to include("updated")
    end

    it "returns error when envelope_key_id is missing" do
      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("envelope_key_id")
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

# ─── AddPaymentToEnvelope ────────────────────────────────────────────────────
RSpec.describe Tools::AddPaymentToEnvelope do
  describe ".call" do
    let(:valid_params) do
      {
        "envelope_key_id" => 5,
        "payment_list_key_id" => 10,
        "amount" => 100.0
      }
    end

    it "adds a payment to an envelope successfully" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bank/enveloppes/5/add")
        .to_return(status: 200, body: "".to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("added")
      expect(result[:message]).to include("added")
    end

    it "sends correctly formatted data" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bank/enveloppes/5/add")
        .with { |req|
          body = JSON.parse(req.body)
          body["paymentListKeyId"] == 10 &&
            body["amount"] == 100.0
        }
        .to_return(status: 200, body: "".to_json, headers: { "Content-Type" => "application/json" })

      described_class.call(params: valid_params, context: octopus_context)

      expect(request_stub).to have_been_requested
    end

    it "returns error when envelope_key_id is missing" do
      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("envelope_key_id")
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

# ─── RemovePaymentFromEnvelope ───────────────────────────────────────────────
RSpec.describe Tools::RemovePaymentFromEnvelope do
  describe ".call" do
    let(:valid_params) do
      {
        "envelope_key_id" => 5,
        "payment_list_key_id" => 10,
        "amount" => 100.0
      }
    end

    it "removes a payment from an envelope successfully" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bank/enveloppes/5/remove")
        .to_return(status: 200, body: "".to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("removed")
      expect(result[:message]).to include("removed")
    end

    it "returns error when envelope_key_id is missing" do
      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("envelope_key_id")
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

# ─── ExportEnvelope ──────────────────────────────────────────────────────────
RSpec.describe Tools::ExportEnvelope do
  describe ".call" do
    let(:valid_params) do
      {
        "envelope_key_id" => 5,
        "format" => "sepa",
        "include_payments" => true
      }
    end

    it "exports an envelope successfully" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bank/enveloppes/5/export")
        .to_return(status: 200, body: { "exportData" => "base64content" }.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:export]).to eq({ "exportData" => "base64content" })
    end

    it "returns error when envelope_key_id is missing" do
      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("envelope_key_id")
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
