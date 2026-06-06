require "rack/test"
require "webmock/rspec"

ENV["RACK_ENV"] = "test"

require_relative "../app"

# Load all support files (RSpec matchers, helpers, etc.)
Dir[File.join(__dir__, "support", "*.rb")].each { |f| require f }

# Disable external network connections in tests.
# Only allow connections to localhost (for Rack::Test).
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  def app
    DokService
  end

  # Helper to POST a tool call
  def call_tool(tool, params: {}, context: {})
    default_context = {
      "project_id" => 1,
      "project_name" => "test-project",
      "oauth_tokens" => {},
      "configuration" => {}
    }

    post "/call",
      { tool: tool, params: params, context: default_context.merge(context) }.to_json,
      { "CONTENT_TYPE" => "application/json" }
  end

  # Default Octopus configuration for tests
  def octopus_config(overrides = {})
    {
      "octopus_user" => "testuser",
      "octopus_password" => "testpass",
      "software_house_id" => "test-uuid-1234",
      "dossier_id" => "42"
    }.merge(overrides)
  end

  # Context with Octopus configuration
  def octopus_context(config_overrides = {})
    { "configuration" => octopus_config(config_overrides) }
  end

  # Stub the Octopus authentication endpoint
  def stub_octopus_auth(token: "test-auth-token")
    stub_request(:post, "#{OctopusClient::BASE_URL}/authentication")
      .to_return(
        status: 200,
        body: { token: token }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # Stub the Octopus dossier connection endpoint.
  # Uses regex to match any dossierId query parameter.
  def stub_octopus_connect_dossier(dossier_token: "test-dossier-token")
    stub_request(:post, /#{Regexp.escape(OctopusClient::BASE_URL)}\/dossiers/)
      .to_return(
        status: 200,
        body: { Dossiertoken: dossier_token }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # Stub both auth + dossier connect (common pattern)
  def stub_octopus_full_auth(auth_token: "test-auth-token", dossier_token: "test-dossier-token")
    stub_octopus_auth(token: auth_token)
    stub_octopus_connect_dossier(dossier_token: dossier_token)
  end
end
