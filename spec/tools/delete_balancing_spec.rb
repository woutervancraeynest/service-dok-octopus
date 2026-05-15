require "spec_helper"

RSpec.describe Tools::DeleteBalancing do
  describe ".call" do
    it "deletes a balancing by item (default mode)" do
      stub_octopus_full_auth
      stub_request(:delete, "#{OctopusClient::BASE_URL}/dossiers/42/balancings/delete")
        .to_return(status: 204, body: "", headers: {})

      result = described_class.call(
        params: {
          "amount" => 100.0,
          "balancing_date" => "2026-05-06",
          "document_keys" => [
            { "bookyear_id" => 10, "journal_key" => "F1", "document_sequence_nr" => 68 },
            { "bookyear_id" => 10, "journal_key" => "A1", "document_sequence_nr" => 111 }
          ]
        },
        context: octopus_context
      )

      expect(result[:status]).to eq("deleted")
      expect(result[:message]).to include("item")
    end

    it "deletes a balancing by document" do
      stub_octopus_full_auth
      stub_request(:delete, "#{OctopusClient::BASE_URL}/dossiers/42/balancings/document/delete")
        .to_return(status: 204, body: "", headers: {})

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
    end

    it "deletes a balancing by booking line" do
      stub_octopus_full_auth
      stub_request(:delete, "#{OctopusClient::BASE_URL}/dossiers/42/balancings/bookingline/delete")
        .to_return(status: 204, body: "", headers: {})

      result = described_class.call(
        params: {
          "mode" => "bookingline",
          "bookyear_id" => 10,
          "journal_key" => "F1",
          "document_sequence_nr" => 68,
          "booking_line_sequence_nr" => 1
        },
        context: octopus_context
      )

      expect(result[:status]).to eq("deleted")
      expect(result[:message]).to include("bookingline")
    end

    it "returns error for invalid mode" do
      result = described_class.call(
        params: { "mode" => "invalid" },
        context: octopus_context
      )

      expect(result[:error]).to include("Invalid mode")
    end

    it "returns error when configuration is missing" do
      result = described_class.call(
        params: { "mode" => "document", "bookyear_id" => 10 },
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end

    it "returns error on API failure" do
      stub_octopus_full_auth
      stub_request(:delete, "#{OctopusClient::BASE_URL}/dossiers/42/balancings/delete")
        .to_return(
          status: 400,
          body: { errorMessage: "Balancing not found" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(
        params: { "amount" => 100.0 },
        context: octopus_context
      )

      expect(result[:error]).to include("Octopus API error")
    end
  end
end
