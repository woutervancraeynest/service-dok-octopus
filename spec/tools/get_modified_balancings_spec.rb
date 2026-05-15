require "spec_helper"

RSpec.describe Tools::GetModifiedBalancings do
  describe ".call" do
    it "returns modified balancings" do
      stub_octopus_full_auth
      balancings = [
        { "amount" => 100.0, "balancingDate" => "2026-05-06" },
        { "amount" => 250.0, "balancingDate" => "2026-05-07" }
      ]

      stub_request(:get, /#{Regexp.escape(OctopusClient::BASE_URL)}\/dossiers\/42\/balancings\/modified/)
        .to_return(
          status: 200,
          body: balancings.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(
        params: { "modified_timestamp" => "2026-05-01 00:00:00.000" },
        context: octopus_context
      )

      expect(result[:balancings]).to be_an(Array)
      expect(result[:total]).to eq(2)
      expect(result[:balancings][0]["amount"]).to eq(100.0)
    end

    it "uses default timestamp when not provided" do
      stub_octopus_full_auth
      request_stub = stub_request(:get, /#{Regexp.escape(OctopusClient::BASE_URL)}\/dossiers\/42\/balancings\/modified/)
        .with(query: hash_including("modifiedTimeStamp" => "2000-01-01 00:00:00.000"))
        .to_return(
          status: 200,
          body: [].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      described_class.call(params: {}, context: octopus_context)

      expect(request_stub).to have_been_requested
    end

    it "returns empty result when no balancings found" do
      stub_octopus_full_auth
      stub_request(:get, /#{Regexp.escape(OctopusClient::BASE_URL)}\/dossiers\/42\/balancings\/modified/)
        .to_return(
          status: 200,
          body: [].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:balancings]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(
        params: {},
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end
