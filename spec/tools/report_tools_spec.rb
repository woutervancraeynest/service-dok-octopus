require "spec_helper"

# Shared examples for all report tools.
# Each report tool requires bookyear_id, calls a POST endpoint,
# and returns { report: ..., total: N }.
RSpec.shared_examples "a report tool" do |tool_class, report_path|
  describe ".call" do
    let(:report_data) { [{ "name" => "Test Report Entry" }] }

    it "returns report data for a bookyear" do
      stub_octopus_full_auth
      stub_request(:post, /#{Regexp.escape(OctopusClient::BASE_URL)}\/dossiers\/42\/reports\/#{report_path}/)
        .to_return(status: 200, body: report_data.to_json, headers: { "Content-Type" => "application/json" })

      result = tool_class.call(
        params: { "bookyear_id" => 1 },
        context: octopus_context
      )

      expect(result[:report]).to eq(report_data)
      expect(result[:total]).to eq(1)
    end

    it "returns error when bookyear_id is missing" do
      result = tool_class.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("bookyear_id")
    end

    it "returns error when configuration is missing" do
      result = tool_class.call(
        params: { "bookyear_id" => 1 },
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end

    it "returns empty report when API returns nil (404)" do
      stub_octopus_full_auth
      stub_request(:post, /#{Regexp.escape(OctopusClient::BASE_URL)}\/dossiers\/42\/reports\/#{report_path}/)
        .to_return(status: 404, body: "".to_json, headers: { "Content-Type" => "application/json" })

      result = tool_class.call(
        params: { "bookyear_id" => 1 },
        context: octopus_context
      )

      expect(result[:report]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "passes optional parameters to the API" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, /#{Regexp.escape(OctopusClient::BASE_URL)}\/dossiers\/42\/reports\/#{report_path}/)
        .with { |req|
          body = JSON.parse(req.body)
          body["fromBookyearKey"]["id"] == 1 &&
            body["toBookyearKey"]["id"] == 2 &&
            body["periodeFrom"] == 3 &&
            body["periodeTo"] == 6 &&
            body["journalKey"] == "V1"
        }
        .to_return(status: 200, body: report_data.to_json, headers: { "Content-Type" => "application/json" })

      tool_class.call(
        params: {
          "bookyear_id" => 1,
          "to_bookyear_id" => 2,
          "period_from" => 3,
          "period_to" => 6,
          "journal_key" => "V1"
        },
        context: octopus_context
      )

      expect(request_stub).to have_been_requested
    end
  end
end

RSpec.describe Tools::ReportOpenClients do
  it_behaves_like "a report tool", Tools::ReportOpenClients, "clients/open"
end

RSpec.describe Tools::ReportOpenSuppliers do
  it_behaves_like "a report tool", Tools::ReportOpenSuppliers, "suppliers/open"
end

RSpec.describe Tools::ReportOpenAccounts do
  it_behaves_like "a report tool", Tools::ReportOpenAccounts, "accounts/open"
end

RSpec.describe Tools::ReportHistoryClients do
  it_behaves_like "a report tool", Tools::ReportHistoryClients, "clients/history"
end

RSpec.describe Tools::ReportHistorySuppliers do
  it_behaves_like "a report tool", Tools::ReportHistorySuppliers, "suppliers/history"
end

RSpec.describe Tools::ReportHistoryAccounts do
  it_behaves_like "a report tool", Tools::ReportHistoryAccounts, "accounts/history"
end

RSpec.describe Tools::ReportHistoryCostCentres do
  it_behaves_like "a report tool", Tools::ReportHistoryCostCentres, "costcentres/history"
end
