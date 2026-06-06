require "spec_helper"

RSpec.describe Tools::InsertBalancing do
  describe ".call" do
    # VISA test case from the field: F1/#62 line 3 (DEBET, -495.48 VISA REF 115)
    # balanced against D4/#2 line 5 (CREDIT, +495.48 ref "31 12 2026/A1/86")
    let(:valid_params) do
      {
        "debet_key"  => { "bookyear_id" => 10, "journal_key" => "F1", "document_sequence_nr" => 62, "line_sequence_nr" => 3 },
        "credit_key" => { "bookyear_id" => 10, "journal_key" => "D4", "document_sequence_nr" => 2,  "line_sequence_nr" => 5 },
        "amount"     => 495.48
      }
    end

    it "inserts a balancing successfully and returns the sent body" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/balancings")
        .to_return(status: 201, body: "", headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("created")
      expect(result[:message]).to include("inserted")
      expect(result[:sent_body]).to include(
        "balanceAmount" => 495.48
      )
    end

    it "sends correctly formatted BalancingServiceData to Octopus" do
      stub_octopus_full_auth
      captured_body = nil
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/balancings")
        .with { |req| captured_body = JSON.parse(req.body); true }
        .to_return(status: 201, body: "", headers: { "Content-Type" => "application/json" })

      described_class.call(params: valid_params, context: octopus_context)

      # Specific field assertions (regression on debet/credit/amount values).
      expect(captured_body["balanceAmount"]).to eq(495.48)
      expect(captured_body["debetKey"]).to eq(
        "bookyearKey" => { "id" => 10 },
        "journalKey" => "F1",
        "documentSequenceNr" => 62,
        "lineSequenceNr" => 3
      )
      expect(captured_body["creditKey"]).to eq(
        "bookyearKey" => { "id" => 10 },
        "journalKey" => "D4",
        "documentSequenceNr" => 2,
        "lineSequenceNr" => 5
      )

      # Schema validation: any deviation from BalancingServiceData fails here.
      expect(captured_body).to match_octopus_schema("BalancingServiceData")
    end

    it "defaults line_sequence_nr to -1 when omitted (invoice header)" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/balancings")
        .with { |req|
          body = JSON.parse(req.body)
          body["debetKey"]["lineSequenceNr"] == -1 &&
            body["creditKey"]["lineSequenceNr"] == 3
        }
        .to_return(status: 201, body: "", headers: { "Content-Type" => "application/json" })

      described_class.call(
        params: {
          # No line_sequence_nr on debet side — should default to -1
          "debet_key"  => { "bookyear_id" => 10, "journal_key" => "V1", "document_sequence_nr" => 50 },
          "credit_key" => { "bookyear_id" => 10, "journal_key" => "F1", "document_sequence_nr" => 62, "line_sequence_nr" => 3 },
          "amount"     => 100.0
        },
        context: octopus_context
      )

      expect(request_stub).to have_been_requested
    end

    it "returns error when debet_key is missing" do
      result = described_class.call(
        params: {
          "credit_key" => { "bookyear_id" => 10, "journal_key" => "F1", "document_sequence_nr" => 62 },
          "amount" => 100.0
        },
        context: octopus_context
      )

      expect(result[:error]).to include("debet_key")
    end

    it "returns error when credit_key is missing" do
      result = described_class.call(
        params: {
          "debet_key" => { "bookyear_id" => 10, "journal_key" => "F1", "document_sequence_nr" => 62 },
          "amount" => 100.0
        },
        context: octopus_context
      )

      expect(result[:error]).to include("credit_key")
    end

    it "returns error when amount is missing" do
      result = described_class.call(
        params: {
          "debet_key"  => { "bookyear_id" => 10, "journal_key" => "F1", "document_sequence_nr" => 62 },
          "credit_key" => { "bookyear_id" => 10, "journal_key" => "D4", "document_sequence_nr" => 2 }
        },
        context: octopus_context
      )

      expect(result[:error]).to include("amount")
    end

    it "returns error when amount is zero or negative" do
      result = described_class.call(
        params: valid_params.merge("amount" => 0),
        context: octopus_context
      )

      expect(result[:error]).to include("amount must be > 0")
    end

    it "returns error when a key is missing a required sub-field" do
      result = described_class.call(
        params: valid_params.merge(
          "debet_key" => { "bookyear_id" => 10, "journal_key" => "F1" } # missing document_sequence_nr
        ),
        context: octopus_context
      )

      expect(result[:error]).to include("debet_key")
      expect(result[:error]).to include("document_sequence_nr")
    end

    it "returns error when configuration is missing" do
      result = described_class.call(
        params: valid_params,
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end

    it "passes Octopus error message through and includes sent_body for debugging" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/balancings")
        .to_return(
          status: 400,
          body: { errorMessage: "Invalid balancing data" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:error]).to include("Octopus API error")
      expect(result[:error]).to include("Invalid balancing data")
      expect(result[:sent_body]).to be_a(Hash)
      expect(result[:sent_body]["balanceAmount"]).to eq(495.48)
    end
  end
end
