require_relative "integration_helper"

RSpec.describe "Authentication", :integration do
  describe "successful authentication flow" do
    it "authenticates and receives an auth token",
       vcr_cassette: "authentication/successful_auth" do
      client = integration_client
      token = client.authenticate

      expect(token).to be_a(String)
      expect(token).not_to be_empty
      expect(client.auth_token).to eq(token)
    end

    it "connects to a dossier and receives a dossier token",
       vcr_cassette: "authentication/dossier_connect" do
      client = integration_client
      client.authenticate
      dossier_token = client.connect_dossier(OCTOPUS_DOSSIER_ID)

      expect(dossier_token).to be_a(String)
      expect(dossier_token).not_to be_empty
      expect(client.dossier_token).to eq(dossier_token)
      expect(client.dossier_id).to eq(OCTOPUS_DOSSIER_ID.to_i)
    end

    it "completes full auth + dossier flow via with_dossier",
       vcr_cassette: "authentication/full_flow" do
      client = integration_client

      result = client.with_dossier(OCTOPUS_DOSSIER_ID) do |c|
        expect(c.auth_token).not_to be_nil
        expect(c.dossier_token).not_to be_nil
        "connected"
      end

      expect(result).to eq("connected")
    end
  end

  describe "error handling" do
    it "raises AuthenticationError with invalid credentials",
       vcr_cassette: "authentication/invalid_credentials" do
      client = OctopusClient::Client.new(
        user: "invalid_user",
        password: "invalid_password",
        software_house_id: OCTOPUS_SOFTWARE_HOUSE_ID
      )

      expect { client.authenticate }.to raise_error(OctopusClient::AuthenticationError)
    end
  end
end
