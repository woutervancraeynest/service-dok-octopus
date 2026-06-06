require "spec_helper"
require "yaml"

# Schema conformance audit.
#
# For every write-tool in manifest.json, this spec verifies that the body the
# tool sends to Octopus matches the corresponding OpenAPI schema (strict mode:
# missing required fields AND unknown extra fields both fail).
#
# When this audit fails on a tool, the body that tool builds is misaligned
# with the official Octopus API. Fix `build_*_data` in the tool or the
# request-wrapping in `vendor/octopus_client/lib/octopus_client/resources/`.
#
# When a new write-tool is added to manifest.json, this audit will fail with
# "No mapping entry for ..." until the tool is added to tool_schema_map.yml
# (either as an audited entry or in tools_without_body).
#
RSpec.describe "Schema conformance audit" do
  TOOL_SCHEMA_MAP = YAML.load_file(File.expand_path("tool_schema_map.yml", __dir__)).freeze

  # All MCP write-tools (read_only_hint: false in manifest.json).
  WRITE_TOOLS_IN_MANIFEST = begin
    manifest = JSON.parse(File.read(File.expand_path("../../manifest.json", __dir__)))
    manifest["tools"].reject { |t| t.dig("annotations", "read_only_hint") }.map { |t| t["name"] }
  end.freeze

  describe "coverage of write-tools" do
    it "every write-tool in manifest.json is either audited or in tools_without_body" do
      audited_tool_names = TOOL_SCHEMA_MAP.reject { |k, _| k == "tools_without_body" }.map do |key, entry|
        entry["tool"] || key
      end.uniq

      skipped_tools = TOOL_SCHEMA_MAP["tools_without_body"] || []
      covered = (audited_tool_names + skipped_tools).uniq

      missing = WRITE_TOOLS_IN_MANIFEST - covered
      extra   = covered - WRITE_TOOLS_IN_MANIFEST

      expect(missing).to be_empty,
        "Write-tools in manifest.json missing from tool_schema_map.yml: #{missing.inspect}. " \
        "Add them to the map (with a schema entry) or to tools_without_body."

      expect(extra).to be_empty,
        "Entries in tool_schema_map.yml that don't exist in manifest.json: #{extra.inspect}. " \
        "Remove stale entries."
    end
  end

  # One it-block per audited mapping entry, so failures are pinpointed.
  TOOL_SCHEMA_MAP.each do |key, entry|
    next if key == "tools_without_body"

    tool_name = entry["tool"] || key
    schema    = entry.fetch("schema")
    http      = entry.fetch("http_method")
    fragment  = entry.fetch("url_fragment")
    fragment_extra = entry["url_fragment_extra"]
    sample    = entry.fetch("sample_params")
    is_pending = entry["pending"] == true
    pending_reason = entry["pending_reason"]

    describe "#{key} (#{tool_name} → #{schema})" do
      let(:context) { octopus_context }
      let(:tool_class) { app_tool_class(tool_name) }

      it "sends a body matching #{schema}" do
        pending(pending_reason || "Known schema mismatch — see tool_schema_map.yml") if is_pending

        stub_octopus_full_auth

        # Catch-all stub: capture body, return success regardless of URL.
        captured_bodies = []
        stub_request(http.to_sym, /#{Regexp.escape(OctopusClient::BASE_URL)}.*#{Regexp.escape(fragment)}.*/)
          .with { |req|
            captured_bodies << { url: req.uri.to_s, body: req.body }
            true
          }
          .to_return(status: success_status_for(http), body: "")

        result = tool_class.call(params: stringify_keys(sample), context: context)

        # Sanity: the tool must have actually attempted the API call. If it
        # short-circuits with a validation error, our schema check is moot.
        if result.is_a?(Hash) && result[:error]
          raise "Tool returned an error before making a request — fix sample_params. " \
                "Error: #{result[:error]}"
        end

        # Find the request that matches the expected url_fragment(_extra).
        matching = captured_bodies.find do |req|
          req[:url].include?(fragment) &&
            (fragment_extra.nil? || req[:url].include?(fragment_extra))
        end

        raise "Tool did not send a #{http.upcase} request matching '#{fragment}'. " \
              "Captured: #{captured_bodies.map { |b| b[:url] }.inspect}" if matching.nil?

        body = JSON.parse(matching[:body])
        expect(body).to match_octopus_schema(schema)
      end
    end
  end

  # ---- helpers ----

  def app_tool_class(tool_name)
    klass = DokService::TOOLS[tool_name]
    raise "Tool '#{tool_name}' not found in app TOOLS registry" unless klass
    klass
  end

  def stringify_keys(obj)
    case obj
    when Hash  then obj.each_with_object({}) { |(k, v), h| h[k.to_s] = stringify_keys(v) }
    when Array then obj.map { |x| stringify_keys(x) }
    else obj
    end
  end

  def success_status_for(http_method)
    case http_method.to_s
    when "post" then 201
    when "put"  then 204
    when "delete" then 204
    else 200
    end
  end
end
