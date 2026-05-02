require "spec_helper"

RSpec.describe Tools::CreateRelation do
  describe ".call" do
    it "creates a relation successfully" do
      stub_octopus_full_auth
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .to_return(
          status: 201,
          body: { "name" => "Acme BV", "relationIdentificationServiceData" => { "relationKey" => { "id" => 99 } } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(
        params: { "name" => "Acme BV", "client" => true, "vat_number" => "BE0123456789" },
        context: octopus_context
      )

      expect(result[:status]).to eq("created")
      expect(result[:message]).to include("created")
    end

    it "updates an existing relation (204)" do
      stub_octopus_full_auth
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .to_return(status: 204, body: "", headers: {})

      result = described_class.call(
        params: { "name" => "Acme BV", "relation_id" => 99 },
        context: octopus_context
      )

      expect(result[:status]).to eq("updated")
      expect(result[:message]).to include("updated")
    end

    it "sends correct Octopus-formatted data" do
      stub_octopus_full_auth
      request_stub = stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .with { |req|
          body = JSON.parse(req.body)
          body["name"] == "Acme BV" &&
            body["currencyCode"] == "EUR" &&
            body["client"] == true &&
            body["supplier"] == false &&
            body["vatNr"] == "BE0123456789" &&
            body["country"] == "BE" &&
            body["ibanAccountNr"] == "BE68539007547034" &&
            body["expirationDays"] == 30
        }
        .to_return(status: 201, body: {}.to_json, headers: { "Content-Type" => "application/json" })

      described_class.call(
        params: {
          "name" => "Acme BV",
          "client" => true,
          "supplier" => false,
          "vat_number" => "BE0123456789",
          "iban" => "BE68539007547034",
          "payment_days" => 30
        },
        context: octopus_context
      )

      expect(request_stub).to have_been_requested
    end

    it "returns error when name is missing" do
      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("name")
    end

    it "returns error when configuration is missing" do
      result = described_class.call(
        params: { "name" => "Test" },
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end

    it "returns error on API failure" do
      stub_octopus_full_auth
      stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .to_return(
          status: 400,
          body: { errorMessage: "Invalid VAT number" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(
        params: { "name" => "Test" },
        context: octopus_context
      )

      expect(result[:error]).to include("Octopus API error")
    end

    it "defaults country to BE and currency to EUR" do
      stub_octopus_full_auth
      request_stub = stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .with { |req|
          body = JSON.parse(req.body)
          body["country"] == "BE" && body["currencyCode"] == "EUR"
        }
        .to_return(status: 201, body: {}.to_json, headers: { "Content-Type" => "application/json" })

      described_class.call(
        params: { "name" => "Test" },
        context: octopus_context
      )

      expect(request_stub).to have_been_requested
    end

    it "maps all optional fields correctly" do
      stub_octopus_full_auth
      request_stub = stub_request(:put, "#{OctopusClient::BASE_URL}/dossiers/42/relations")
        .with { |req|
          body = JSON.parse(req.body)
          body["firstName"] == "Jan" &&
            body["email"] == "jan@test.be" &&
            body["telephone"] == "+3212345678" &&
            body["mobile"] == "+32498765432" &&
            body["streetAndNr"] == "Kerkstraat 1" &&
            body["postalCode"] == "1000" &&
            body["city"] == "Brussel" &&
            body["bicCode"] == "GEBABEBB" &&
            body["country"] == "NL" &&
            body["currencyCode"] == "USD" &&
            body["relationIdentificationServiceData"]["externalRelationId"] == 999
        }
        .to_return(status: 201, body: {}.to_json, headers: { "Content-Type" => "application/json" })

      described_class.call(
        params: {
          "name" => "Test BV",
          "first_name" => "Jan",
          "email" => "jan@test.be",
          "telephone" => "+3212345678",
          "mobile" => "+32498765432",
          "street_and_nr" => "Kerkstraat 1",
          "postal_code" => "1000",
          "city" => "Brussel",
          "bic" => "GEBABEBB",
          "country" => "NL",
          "currency_code" => "USD",
          "external_relation_id" => 999
        },
        context: octopus_context
      )

      expect(request_stub).to have_been_requested
    end
  end
end
