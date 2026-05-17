require "spec_helper"

# ─── GetCostCentres ──────────────────────────────────────────────────────────
RSpec.describe Tools::GetCostCentres do
  describe ".call" do
    let(:cost_centres) { [{ "description" => "Marketing", "costCentreKey" => { "id" => 1 } }] }

    it "returns cost centres" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/costcentres")
        .to_return(status: 200, body: cost_centres.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:cost_centres]).to eq(cost_centres)
      expect(result[:total]).to eq(1)
    end

    it "returns empty list when no data" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/costcentres")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:cost_centres]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end

# ─── GetActiveCostCentres ────────────────────────────────────────────────────
RSpec.describe Tools::GetActiveCostCentres do
  describe ".call" do
    let(:cost_centres) { [{ "description" => "Sales", "costCentreKey" => { "id" => 2 } }] }

    it "returns active cost centres" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/costcentres/active")
        .to_return(status: 200, body: cost_centres.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:cost_centres]).to eq(cost_centres)
      expect(result[:total]).to eq(1)
    end

    it "returns empty list when no data" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/costcentres/active")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:cost_centres]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end

# ─── GetProducts ─────────────────────────────────────────────────────────────
RSpec.describe Tools::GetProducts do
  describe ".call" do
    let(:products) { [{ "description" => "Widget", "productKey" => { "id" => 1 } }] }

    it "returns products" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/products")
        .to_return(status: 200, body: products.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:products]).to eq(products)
      expect(result[:total]).to eq(1)
    end

    it "returns empty list when no data" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/products")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:products]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end

# ─── GetProductGroups ────────────────────────────────────────────────────────
RSpec.describe Tools::GetProductGroups do
  describe ".call" do
    let(:product_groups) { [{ "description" => "Services", "id" => 1 }] }

    it "returns product groups" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/productgroups")
        .to_return(status: 200, body: product_groups.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:product_groups]).to eq(product_groups)
      expect(result[:total]).to eq(1)
    end

    it "returns empty list when no data" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/productgroups")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:product_groups]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end

# ─── GetVatCodes ─────────────────────────────────────────────────────────────
RSpec.describe Tools::GetVatCodes do
  describe ".call" do
    let(:vat_codes) { [{ "code" => "21", "percentage" => 21.0 }] }

    it "returns VAT codes" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/vatcodes")
        .to_return(status: 200, body: vat_codes.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:vat_codes]).to eq(vat_codes)
      expect(result[:total]).to eq(1)
    end

    it "returns empty list when no data" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/vatcodes")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:vat_codes]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end

# ─── GetCurrencies ───────────────────────────────────────────────────────────
RSpec.describe Tools::GetCurrencies do
  describe ".call" do
    let(:currencies) { [{ "code" => "EUR", "description" => "Euro" }] }

    it "returns currencies" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/currencies")
        .to_return(status: 200, body: currencies.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:currencies]).to eq(currencies)
      expect(result[:total]).to eq(1)
    end

    it "returns empty list when no data" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/currencies")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:currencies]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end

# ─── GetCustomFields ─────────────────────────────────────────────────────────
RSpec.describe Tools::GetCustomFields do
  describe ".call" do
    let(:custom_fields) { [{ "name" => "MyField", "type" => "text" }] }

    it "returns custom fields" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/customfields")
        .to_return(status: 200, body: custom_fields.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:custom_fields]).to eq(custom_fields)
      expect(result[:total]).to eq(1)
    end

    it "returns empty list when no data" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/customfields")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:custom_fields]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end
