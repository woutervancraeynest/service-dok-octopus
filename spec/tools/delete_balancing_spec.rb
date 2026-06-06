require "spec_helper"

RSpec.describe Tools::DeleteBalancing do
  describe ".call" do
    let(:valid_item_params) do
      {
        "mode" => "item",
        "debet_key"  => { "bookyear_id" => 10, "journal_key" => "F1", "document_sequence_nr" => 62, "line_sequence_nr" => 3 },
        "credit_key" => { "bookyear_id" => 10, "journal_key" => "D4", "document_sequence_nr" => 2,  "line_sequence_nr" => 5 }
      }
    end

    # =========================================================================
    # Mode 'item'
    # =========================================================================

    it "deletes a balancing in item mode and sends DeleteBalancingItemRequest" do
      stub_octopus_full_auth
      captured_body = nil
      stub_request(:delete, "#{OctopusClient::BASE_URL}/dossiers/42/balancings/delete")
        .with { |req| captured_body = JSON.parse(req.body); true }
        .to_return(status: 204, body: "", headers: {})

      result = described_class.call(params: valid_item_params, context: octopus_context)

      expect(result[:status]).to eq("deleted")
      expect(result[:message]).to include("item")
      expect(captured_body).to eq(
        "debetKey" => {
          "bookyearKey" => { "id" => 10 },
          "journalKey" => "F1",
          "documentSequenceNr" => 62,
          "lineSequenceNr" => 3
        },
        "creditKey" => {
          "bookyearKey" => { "id" => 10 },
          "journalKey" => "D4",
          "documentSequenceNr" => 2,
          "lineSequenceNr" => 5
        }
      )
      expect(captured_body).to match_octopus_schema("DeleteBalancingItemRequest")
    end

    it "defaults line_sequence_nr to -1 in item mode when omitted" do
      stub_octopus_full_auth
      request_stub = stub_request(:delete, "#{OctopusClient::BASE_URL}/dossiers/42/balancings/delete")
        .with { |req|
          body = JSON.parse(req.body)
          body["debetKey"]["lineSequenceNr"] == -1 &&
            body["creditKey"]["lineSequenceNr"] == -1
        }
        .to_return(status: 204, body: "")

      described_class.call(
        params: {
          "mode" => "item",
          "debet_key"  => { "bookyear_id" => 10, "journal_key" => "V1", "document_sequence_nr" => 50 },
          "credit_key" => { "bookyear_id" => 10, "journal_key" => "A1", "document_sequence_nr" => 70 }
        },
        context: octopus_context
      )

      expect(request_stub).to have_been_requested
    end

    it "returns error in item mode when debet_key is missing" do
      result = described_class.call(
        params: { "mode" => "item", "credit_key" => valid_item_params["credit_key"] },
        context: octopus_context
      )

      expect(result[:error]).to include("debet_key")
    end

    it "returns error in item mode when credit_key is missing" do
      result = described_class.call(
        params: { "mode" => "item", "debet_key" => valid_item_params["debet_key"] },
        context: octopus_context
      )

      expect(result[:error]).to include("credit_key")
    end

    # =========================================================================
    # Mode 'bookingline'
    # =========================================================================

    it "deletes a balancing by booking line with BalancingKeyServiceData (lineSequenceNr, not bookingLineSequenceNr)" do
      stub_octopus_full_auth
      captured_body = nil
      stub_request(:delete, "#{OctopusClient::BASE_URL}/dossiers/42/balancings/bookingline/delete")
        .with { |req| captured_body = JSON.parse(req.body); true }
        .to_return(status: 204, body: "")

      result = described_class.call(
        params: {
          "mode" => "bookingline",
          "bookyear_id" => 10,
          "journal_key" => "F1",
          "document_sequence_nr" => 62,
          "line_sequence_nr" => 3
        },
        context: octopus_context
      )

      expect(result[:status]).to eq("deleted")
      expect(result[:message]).to include("bookingline")
      expect(captured_body).to eq(
        "bookyearKey" => { "id" => 10 },
        "journalKey" => "F1",
        "documentSequenceNr" => 62,
        "lineSequenceNr" => 3
      )
      expect(captured_body).to match_octopus_schema("BalancingKeyServiceData")
    end

    it "returns error in bookingline mode when line_sequence_nr is missing" do
      result = described_class.call(
        params: {
          "mode" => "bookingline",
          "bookyear_id" => 10,
          "journal_key" => "F1",
          "document_sequence_nr" => 62
        },
        context: octopus_context
      )

      expect(result[:error]).to include("line_sequence_nr")
    end

    # =========================================================================
    # Mode 'document'
    # =========================================================================

    it "deletes a balancing by document with DocumentKeyServiceData (journal, NOT journalKey)" do
      stub_octopus_full_auth
      captured_body = nil
      stub_request(:delete, "#{OctopusClient::BASE_URL}/dossiers/42/balancings/document/delete")
        .with { |req| captured_body = JSON.parse(req.body); true }
        .to_return(status: 204, body: "")

      result = described_class.call(
        params: {
          "mode" => "document",
          "bookyear_id" => 10,
          "journal_key" => "A1",
          "document_sequence_nr" => 111
        },
        context: octopus_context
      )

      expect(result[:status]).to eq("deleted")
      expect(result[:message]).to include("document")
      expect(captured_body).to eq(
        "bookyearKey" => { "id" => 10 },
        "journal" => "A1",
        "documentSequenceNr" => 111
      )
      expect(captured_body).to match_octopus_schema("DocumentKeyServiceData")
    end

    it "returns error in document mode when fields are missing" do
      result = described_class.call(
        params: { "mode" => "document", "bookyear_id" => 10 },
        context: octopus_context
      )

      expect(result[:error]).to include("Missing")
    end

    # =========================================================================
    # Generic
    # =========================================================================

    it "returns error for invalid mode" do
      result = described_class.call(
        params: { "mode" => "invalid" },
        context: octopus_context
      )

      expect(result[:error]).to include("Invalid mode")
    end

    it "returns error when configuration is missing" do
      result = described_class.call(
        params: valid_item_params,
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end

    it "passes Octopus error message through and includes sent_body for debugging" do
      stub_octopus_full_auth
      stub_request(:delete, "#{OctopusClient::BASE_URL}/dossiers/42/balancings/delete")
        .to_return(
          status: 400,
          body: { errorMessage: "Balancing not found" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_item_params, context: octopus_context)

      expect(result[:error]).to include("Octopus API error")
      expect(result[:error]).to include("Balancing not found")
      expect(result[:sent_body]).to be_a(Hash)
      expect(result[:sent_body]["debetKey"]).to include("lineSequenceNr" => 3)
    end
  end
end
