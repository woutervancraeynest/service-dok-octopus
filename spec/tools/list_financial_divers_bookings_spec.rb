require "spec_helper"

RSpec.describe Tools::ListFinancialDiversBookings do
  describe ".call" do
    let(:bookings) do
      [
        {
          "journalKey" => "F1",
          "documentSequenceNr" => 1,
          "documentDate" => "2024-03-15",
          "bookingLines" => [
            { "type" => "A", "accountKey" => 550000, "amount" => 1000.0 }
          ]
        }
      ]
    end

    it "returns bookings without filters" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/financialdiversbookings")
        .to_return(status: 200, body: bookings.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:bookings]).to eq(bookings)
      expect(result[:total]).to eq(1)
    end

    it "passes filter parameters" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/financialdiversbookings")
        .with(query: { "bookyearKeyId" => "1", "journalKey" => "F1" })
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_key" => "F1" },
        context: octopus_context
      )

      expect(result[:bookings]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "handles single booking response (non-array)" do
      stub_octopus_full_auth
      single_booking = bookings.first
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/financialdiversbookings")
        .to_return(status: 200, body: single_booking.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:bookings]).to be_an(Array)
      expect(result[:total]).to eq(1)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end
