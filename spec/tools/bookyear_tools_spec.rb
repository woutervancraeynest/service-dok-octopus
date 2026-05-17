require "spec_helper"

# ─── CreateBookyear ──────────────────────────────────────────────────────────
RSpec.describe Tools::CreateBookyear do
  describe ".call" do
    let(:valid_params) do
      {
        "description" => "Boekjaar 2025",
        "start_date" => "2025-01-01",
        "end_date" => "2025-12-31",
        "number_of_periods" => 12
      }
    end

    it "creates a bookyear successfully" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears")
        .to_return(
          status: 201,
          body: { "bookyearKey" => { "id" => 5 } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("created")
      expect(result[:message]).to include("created")
    end

    it "sends correctly formatted data" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears")
        .with { |req|
          body = JSON.parse(req.body)
          body["description"] == "Boekjaar 2025" &&
            body["startDate"] == "2025-01-01" &&
            body["endDate"] == "2025-12-31" &&
            body["numberOfPeriods"] == 12 &&
            body["currencyCode"] == "EUR"
        }
        .to_return(
          status: 201,
          body: { "bookyearKey" => { "id" => 5 } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

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
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears")
        .to_return(
          status: 400,
          body: { errorMessage: "Invalid bookyear" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:error]).to include("Octopus API error")
    end
  end
end

# ─── UpdateBookyear ──────────────────────────────────────────────────────────
RSpec.describe Tools::UpdateBookyear do
  describe ".call" do
    let(:valid_params) do
      {
        "bookyear_id" => 5,
        "description" => "Boekjaar 2025 (updated)"
      }
    end

    it "updates a bookyear successfully" do
      stub_octopus_full_auth
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears")
        .to_return(status: 204, body: "", headers: {})

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("updated")
      expect(result[:message]).to include("updated")
    end

    it "sends correctly formatted data" do
      stub_octopus_full_auth
      request_stub = stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears")
        .with { |req|
          body = JSON.parse(req.body)
          body["bookyearKey"]["id"] == 5 &&
            body["description"] == "Boekjaar 2025 (updated)"
        }
        .to_return(status: 204, body: "", headers: {})

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
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears")
        .to_return(
          status: 400,
          body: { errorMessage: "Invalid bookyear" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:error]).to include("Octopus API error")
    end
  end
end

# ─── BookBookyear ────────────────────────────────────────────────────────────
RSpec.describe Tools::BookBookyear do
  describe ".call" do
    let(:valid_params) do
      {
        "from_bookyear_id" => 4,
        "to_bookyear_id" => 5,
        "booking_date" => "2025-01-01"
      }
    end

    it "books a bookyear successfully" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears/book")
        .to_return(
          status: 200,
          body: { "result" => "ok" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("booked")
      expect(result[:message]).to include("booked")
    end

    it "sends correctly formatted data" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears/book")
        .with { |req|
          body = JSON.parse(req.body)
          body["fromBookyearId"] == 4 &&
            body["toBookyearId"] == 5 &&
            body["bookingDate"] == "2025-01-01"
        }
        .to_return(
          status: 200,
          body: { "result" => "ok" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

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
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/bookyears/book")
        .to_return(
          status: 400,
          body: { errorMessage: "Cannot book" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:error]).to include("Octopus API error")
    end
  end
end
