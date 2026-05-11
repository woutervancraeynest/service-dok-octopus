require "vcr"

ENV["RACK_ENV"] = "test"

require_relative "../../app"

# ---------------------------------------------------------------------------
# Sandbox credentials
#
# Defaults are the Octopus sandbox demo dossier.  Override via ENV or .env.test
# for CI / other environments.
#
# The SOFTWARE_HOUSE_ID must be obtained from Octopus (webservice@octopus.be).
# Without it, no API call will succeed — tests will be pending until it's set.
# ---------------------------------------------------------------------------
OCTOPUS_USER              = ENV.fetch("OCTOPUS_USER", "bybe27@D05000000")
OCTOPUS_PASSWORD          = ENV.fetch("OCTOPUS_PASSWORD", "bybe27")
OCTOPUS_SOFTWARE_HOUSE_ID = ENV.fetch("OCTOPUS_SOFTWARE_HOUSE_ID", "<SOFTWARE_HOUSE_ID>")
OCTOPUS_DOSSIER_ID        = ENV.fetch("OCTOPUS_DOSSIER_ID", "49555")

# ---------------------------------------------------------------------------
# VCR configuration
# ---------------------------------------------------------------------------
VCR.configure do |c|
  c.cassette_library_dir = "spec/integration/cassettes"
  c.hook_into :webmock

  # :once   — record the first time, replay thereafter (default for integration)
  # :none   — never record, only replay (CI mode after cassettes are committed)
  # :all    — always re-record (useful when re-recording after API changes)
  c.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }

  # ---- Sanitize credentials in cassettes ----

  # Static strings — replaced in both request and response bodies/headers
  c.filter_sensitive_data("<OCTOPUS_USER>")     { OCTOPUS_USER }
  c.filter_sensitive_data("<OCTOPUS_PASSWORD>") { OCTOPUS_PASSWORD }

  if OCTOPUS_SOFTWARE_HOUSE_ID != "<SOFTWARE_HOUSE_ID>"
    c.filter_sensitive_data("<SOFTWARE_HOUSE_ID>") { OCTOPUS_SOFTWARE_HOUSE_ID }
  end

  # Dynamic tokens — sanitized via before_record hook because their values
  # change on every request and can't be matched as static strings.
  c.before_record do |interaction|
    # Auth token in response body
    if interaction.response.body =~ /"token"\s*:\s*"([^"]+)"/
      interaction.response.body.gsub!($1, "<AUTH_TOKEN>")
    end

    # Dossier token in response body (both casings)
    if interaction.response.body =~ /"[Dd]ossiertoken"\s*:\s*"([^"]+)"/
      interaction.response.body.gsub!($1, "<DOSSIER_TOKEN>")
    end

    # Auth token in request headers
    if interaction.request.headers["Token"]
      interaction.request.headers["Token"] = ["<AUTH_TOKEN>"]
    end

    # Dossier token in request headers
    if interaction.request.headers["Dossiertoken"]
      interaction.request.headers["Dossiertoken"] = ["<DOSSIER_TOKEN>"]
    end
    if interaction.request.headers["Dossiertoken"] || interaction.request.headers["dossierToken"]
      key = interaction.request.headers.key?("dossierToken") ? "dossierToken" : "Dossiertoken"
      interaction.request.headers[key] = ["<DOSSIER_TOKEN>"]
    end

    # Software house UUID in request headers
    if interaction.request.headers["Softwarehouseuuid"]
      interaction.request.headers["Softwarehouseuuid"] = ["<SOFTWARE_HOUSE_ID>"]
    end

    # Password in request body
    if interaction.request.body.include?(OCTOPUS_PASSWORD)
      interaction.request.body.gsub!(OCTOPUS_PASSWORD, "<OCTOPUS_PASSWORD>")
    end
    if interaction.request.body.include?(OCTOPUS_USER)
      interaction.request.body.gsub!(OCTOPUS_USER, "<OCTOPUS_USER>")
    end

    # Filter Set-Cookie headers (session cookies)
    if interaction.response.headers["Set-Cookie"]
      interaction.response.headers["Set-Cookie"] = ["<FILTERED_COOKIE>"]
    end
  end
end

# ---------------------------------------------------------------------------
# RSpec configuration for integration tests
# ---------------------------------------------------------------------------
RSpec.configure do |config|
  # Helper: are we configured to talk to the real API?
  # When using placeholder defaults, we are NOT configured for live recording.
  config.add_setting :octopus_configured
  config.octopus_configured = ENV.key?("OCTOPUS_SOFTWARE_HOUSE_ID") &&
                              ENV["OCTOPUS_SOFTWARE_HOUSE_ID"] != "" &&
                              ENV.key?("OCTOPUS_DOSSIER_ID") &&
                              ENV["OCTOPUS_DOSSIER_ID"] != ""

  # Skip integration tests when credentials are not configured and no cassettes exist
  config.before(:each, :integration) do |example|
    cassette_path = File.join(
      VCR.configuration.cassette_library_dir,
      example.metadata[:vcr_cassette] || example.metadata[:description].parameterize
    ) + ".yml"

    unless RSpec.configuration.octopus_configured || File.exist?(cassette_path)
      skip "Skipped: OCTOPUS_SOFTWARE_HOUSE_ID and OCTOPUS_DOSSIER_ID not set " \
           "and no cassette found. Set these environment variables to record cassettes."
    end
  end

  # Wrap each test that specifies a vcr_cassette in VCR.use_cassette
  config.around(:each, :vcr_cassette) do |example|
    VCR.use_cassette(example.metadata[:vcr_cassette]) do
      example.run
    end
  end
end

# ---------------------------------------------------------------------------
# Integration test helpers
# ---------------------------------------------------------------------------

# Build a real context hash with sandbox credentials.
def integration_context(config_overrides = {})
  {
    "configuration" => {
      "octopus_user" => OCTOPUS_USER,
      "octopus_password" => OCTOPUS_PASSWORD,
      "software_house_id" => OCTOPUS_SOFTWARE_HOUSE_ID,
      "dossier_id" => OCTOPUS_DOSSIER_ID
    }.merge(config_overrides)
  }
end

# Build an OctopusClient with sandbox credentials.
def integration_client
  OctopusClient::Client.new(
    user: OCTOPUS_USER,
    password: OCTOPUS_PASSWORD,
    software_house_id: OCTOPUS_SOFTWARE_HOUSE_ID
  )
end
