require "spec_helper"

RSpec.describe DokService do
  describe "GET /health" do
    it "returns 200 OK" do
      get "/health"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("OK")
    end
  end

  describe "POST /call" do
    context "with a known tool" do
      before { stub_octopus_full_auth }

      it "dispatches to list_dossiers tool" do
        dossiers = [{ "dossierKey" => { "id" => 1 }, "dossierDescription" => "Test" }]
        stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers")
          .to_return(status: 200, body: dossiers.to_json, headers: { "Content-Type" => "application/json" })

        call_tool("list_dossiers", context: octopus_context)

        expect(last_response.status).to eq(200)
        result = JSON.parse(last_response.body)
        expect(result["total"]).to eq(1)
        expect(result["dossiers"]).to be_an(Array)
      end
    end

    it "returns error for unknown tool" do
      call_tool("nonexistent_tool")

      expect(last_response.status).to eq(200)
      result = JSON.parse(last_response.body)
      expect(result["error"]).to include("Unknown tool")
    end

    it "returns error for invalid JSON body" do
      post "/call", "not json", { "CONTENT_TYPE" => "application/json" }

      expect(last_response.status).to eq(400)
      result = JSON.parse(last_response.body)
      expect(result["error"]).to include("Invalid JSON")
    end

    it "returns JSON content type" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      call_tool("list_dossiers", context: octopus_context)

      expect(last_response.content_type).to include("application/json")
    end

    it "returns error when configuration is missing" do
      call_tool("list_dossiers", context: { "configuration" => {} })

      expect(last_response.status).to eq(200)
      result = JSON.parse(last_response.body)
      expect(result["error"]).to include("Missing Octopus configuration")
    end

    it "handles missing tool key in body gracefully" do
      post "/call",
        { params: {}, context: {} }.to_json,
        { "CONTENT_TYPE" => "application/json" }

      expect(last_response.status).to eq(200)
      result = JSON.parse(last_response.body)
      expect(result["error"]).to include("Unknown tool")
    end

    it "defaults params and context to empty hashes when missing" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      post "/call",
        { tool: "list_dossiers", context: octopus_context }.to_json,
        { "CONTENT_TYPE" => "application/json" }

      expect(last_response.status).to eq(200)
      result = JSON.parse(last_response.body)
      expect(result).to have_key("dossiers")
    end

    context "with write tools" do
      it "dispatches to create_relation tool" do
        stub_octopus_full_auth
        stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
          .to_return(status: 201, body: {}.to_json, headers: { "Content-Type" => "application/json" })

        call_tool("create_relation",
          params: { "name" => "Test BV" },
          context: octopus_context
        )

        expect(last_response.status).to eq(200)
        result = JSON.parse(last_response.body)
        expect(result["status"]).to eq("created")
      end

      it "dispatches to create_buy_sell_booking tool" do
        stub_octopus_full_auth
        stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/buysellbookings")
          .to_return(status: 201, body: "", headers: {})

        call_tool("create_buy_sell_booking",
          params: {
            "bookyear_id" => 1, "journal_key" => "A1", "document_sequence_nr" => 1,
            "period_nr" => 1, "document_date" => "2024-01-15", "expiry_date" => "2024-02-15",
            "amount" => 121.0, "relation_id" => 10
          },
          context: octopus_context
        )

        expect(last_response.status).to eq(200)
        result = JSON.parse(last_response.body)
        expect(result["status"]).to eq("created")
      end
    end

    context "when tool raises unexpected exception" do
      it "returns internal error message" do
        # Stub auth to succeed but force an unexpected error
        allow(Tools::ListDossiers).to receive(:call).and_raise(RuntimeError, "something unexpected broke")

        call_tool("list_dossiers", context: octopus_context)

        expect(last_response.status).to eq(200)
        result = JSON.parse(last_response.body)
        expect(result["error"]).to include("Internal error")
        expect(result["error"]).to include("something unexpected broke")
      end
    end
  end
end
