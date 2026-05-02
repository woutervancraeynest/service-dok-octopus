require "spec_helper"

RSpec.describe Tools::CreateInvoice do
  describe ".call" do
    let(:valid_params) do
      {
        "bookyear_id" => 1,
        "journal_key" => "V1",
        "document_sequence_nr" => 10,
        "period_nr" => 3,
        "document_date" => "2024-03-15",
        "expiry_date" => "2024-04-15",
        "relation_id" => 10,
        "reference" => "PO-2024-100",
        "invoice_lines" => [
          {
            "description" => "Consulting services",
            "count" => 10,
            "unit_price" => 100.0,
            "unit" => "hours",
            "vat_code" => "21",
            "booking_account_nr" => 700000
          }
        ]
      }
    end

    it "creates an invoice successfully" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/invoices")
        .to_return(status: 201, body: "", headers: {})

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:status]).to eq("created")
      expect(result[:message]).to include("V1")
    end

    it "sends correctly formatted invoice data" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/invoices")
        .with { |req|
          data = JSON.parse(req.body)
          data["bookyearKey"]["id"] == 1 &&
            data["journalKey"] == "V1" &&
            data["currencyCode"] == "EUR" &&
            data["exchangeRate"] == 1.0 &&
            data["invoiceLines"][0]["description"] == "Consulting services" &&
            data["invoiceLines"][0]["count"] == 10.0 &&
            data["invoiceLines"][0]["unitPrice"] == 100.0 &&
            data["invoiceLines"][0]["unit"] == "hours" &&
            data["invoiceLines"][0]["vatCodeKey"] == "21" &&
            data["invoiceLines"][0]["bookingAccountNr"] == 700000
        }
        .to_return(status: 201, body: "", headers: {})

      described_class.call(params: valid_params, context: octopus_context)
      expect(request_stub).to have_been_requested
    end

    it "returns error when required params are missing" do
      result = described_class.call(
        params: { "bookyear_id" => 1 },
        context: octopus_context
      )

      expect(result[:error]).to include("Missing required parameters")
    end

    it "returns error when relation is not specified" do
      params = valid_params.tap { |p| p.delete("relation_id") }
      result = described_class.call(params: params, context: octopus_context)

      expect(result[:error]).to include("relation_id")
    end

    it "returns error when invoice_lines is empty" do
      params = valid_params.merge("invoice_lines" => [])
      result = described_class.call(params: params, context: octopus_context)

      expect(result[:error]).to include("invoice_line")
    end

    it "returns error when invoice_lines is missing" do
      params = valid_params.tap { |p| p.delete("invoice_lines") }
      result = described_class.call(params: params, context: octopus_context)

      expect(result[:error]).to include("invoice_line")
    end

    it "handles discount and product number on lines" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/invoices")
        .with { |req|
          lines = JSON.parse(req.body)["invoiceLines"]
          lines[0]["discountPercentage"] == 10.0 &&
            lines[0]["externProductNr"] == "PROD-001"
        }
        .to_return(status: 201, body: "", headers: {})

      params = valid_params.merge(
        "invoice_lines" => [{
          "description" => "Product",
          "count" => 1,
          "unit_price" => 50.0,
          "vat_code" => "21",
          "discount_percentage" => 10.0,
          "product_nr" => "PROD-001"
        }]
      )

      described_class.call(params: params, context: octopus_context)
      expect(request_stub).to have_been_requested
    end

    it "supports external_relation_id" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/invoices")
        .with { |req|
          data = JSON.parse(req.body)
          data["relationIdentificationServiceData"]["externalRelationId"] == 42
        }
        .to_return(status: 201, body: "", headers: {})

      params = valid_params.merge("external_relation_id" => 42).tap { |p| p.delete("relation_id") }
      described_class.call(params: params, context: octopus_context)
      expect(request_stub).to have_been_requested
    end

    it "maps invoice line cost_centre_id" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/invoices")
        .with { |req|
          lines = JSON.parse(req.body)["invoiceLines"]
          lines[0]["costCentreKey"]["id"] == 3
        }
        .to_return(status: 201, body: "", headers: {})

      params = valid_params.merge(
        "invoice_lines" => [{
          "description" => "Service", "count" => 1, "unit_price" => 100.0,
          "vat_code" => "21", "cost_centre_id" => 3
        }]
      )

      described_class.call(params: params, context: octopus_context)
      expect(request_stub).to have_been_requested
    end

    it "maps optional fields: comment, order_reference, custom currency" do
      stub_octopus_full_auth
      request_stub = stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/invoices")
        .with { |req|
          data = JSON.parse(req.body)
          data["comment"] == "Invoice comment" &&
            data["orderReference"] == "PO-456" &&
            data["currencyCode"] == "GBP" &&
            data["exchangeRate"] == 0.86
        }
        .to_return(status: 201, body: "", headers: {})

      params = valid_params.merge(
        "comment" => "Invoice comment",
        "order_reference" => "PO-456",
        "currency_code" => "GBP",
        "exchange_rate" => 0.86
      )

      described_class.call(params: params, context: octopus_context)
      expect(request_stub).to have_been_requested
    end

    it "returns error on journal closed (403)" do
      stub_octopus_full_auth
      stub_request(:post, "#{OctopusClient::BASE_URL}/dossiers/42/invoices")
        .to_return(
          status: 403,
          body: { errorMessage: "Journal in use" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(params: valid_params, context: octopus_context)

      expect(result[:error]).to include("Journal is closed")
    end
  end
end
