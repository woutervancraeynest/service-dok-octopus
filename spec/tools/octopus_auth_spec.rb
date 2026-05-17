require "spec_helper"

# Test the OctopusAuth concern via a simple test class.
# We use Tools::ListDossiers (with_octopus_client) and
# Tools::GetBookyears (with_dossier_connection) as proxies.

RSpec.describe Tools::OctopusAuth do
  describe "with_octopus_client" do
    it "returns error when configuration key is nil" do
      result = Tools::ListDossiers.call(
        params: {},
        context: { "not_configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end

    it "returns error when config values are whitespace-only" do
      result = Tools::ListDossiers.call(
        params: {},
        context: { "configuration" => {
          "octopus_user" => "  ",
          "octopus_password" => "pass",
          "software_house_id" => "uuid"
        } }
      )

      expect(result[:error]).to include("octopus_user")
    end

    it "returns error on Faraday::Error (network failure)" do
      stub_request(:post, "#{OctopusClient::BASE_URL}/authentication")
        .to_raise(Faraday::ConnectionFailed.new("Connection refused"))

      result = Tools::ListDossiers.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("Connection error")
    end

    it "returns error on ApiError" do
      stub_octopus_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers")
        .to_return(
          status: 500,
          body: { errorMessage: "Server exploded" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = Tools::ListDossiers.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("Octopus API error")
    end
  end

  describe "with_dossier_connection" do
    it "returns error on Faraday::Error during dossier connect" do
      stub_octopus_auth
      stub_request(:post, /#{Regexp.escape(OctopusClient::BASE_URL)}\/dossiers/)
        .to_raise(Faraday::ConnectionFailed.new("Connection reset"))

      result = Tools::GetBookyears.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("Connection error")
    end

    it "returns error on AuthenticationError during dossier connect" do
      stub_octopus_auth
      stub_request(:post, /#{Regexp.escape(OctopusClient::BASE_URL)}\/dossiers/)
        .to_return(
          status: 401,
          body: { errorMessage: "Token expired" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = Tools::GetBookyears.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("Authentication failed")
    end

    it "returns error when dossier_id is not numeric" do
      context = {
        "configuration" => {
          "octopus_user" => "user",
          "octopus_password" => "pass",
          "software_house_id" => "uuid",
          "dossier_id" => "abc"
        }
      }

      result = Tools::GetBookyears.call(params: {}, context: context)

      expect(result[:error]).to include("Invalid dossier_id")
      expect(result[:error]).to include("numeric")
    end
  end
end
