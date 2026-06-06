require "spec_helper"
require "yaml"

# Cassette coverage audit.
#
# Enforces the policy: every MCP write-tool must have at least one VCR
# integration cassette against the real Octopus API, OR be explicitly listed
# in the cassette_gap_allowlist.yml with a reason.
#
# A new write-tool added to manifest.json that is in neither file fails this
# audit, blocking the merge.
#
# When a tool's cassette is recorded:
#   - Move the entry from cassette_gap_allowlist.yml to tool_cassette_coverage.yml
#   - Add the cassette path(s)
#
RSpec.describe "Cassette coverage audit" do
  COVERAGE_MAP = YAML.load_file(File.expand_path("tool_cassette_coverage.yml", __dir__)).freeze
  ALLOWLIST    = YAML.load_file(File.expand_path("cassette_gap_allowlist.yml", __dir__)).freeze
  REPO_ROOT    = File.expand_path("../..", __dir__)

  WRITE_TOOLS_IN_MANIFEST = begin
    manifest = JSON.parse(File.read(File.join(REPO_ROOT, "manifest.json")))
    manifest["tools"].reject { |t| t.dig("annotations", "read_only_hint") }.map { |t| t["name"] }
  end.freeze

  it "reports current coverage" do
    covered = COVERAGE_MAP.keys
    todo    = ALLOWLIST.keys
    total   = WRITE_TOOLS_IN_MANIFEST.length
    pct     = (covered.length.to_f / total * 100).round(1)

    $stdout.puts ""
    $stdout.puts "Cassette coverage: #{covered.length} / #{total} write-tools covered " \
                 "(#{pct}%, #{todo.length} TODOs)"
    $stdout.puts "Covered:    #{covered.sort.join(", ")}"
    $stdout.puts "Allowlist:  #{todo.sort.join(", ")}" if todo.any?
    $stdout.puts ""

    expect(covered.length + todo.length).to eq(total),
      "Coverage map + allowlist must together cover every write-tool"
  end

  it "every write-tool in manifest.json is either covered or allowlisted" do
    covered = COVERAGE_MAP.keys
    todo    = ALLOWLIST.keys
    both    = covered & todo
    missing = WRITE_TOOLS_IN_MANIFEST - covered - todo
    extra   = (covered + todo) - WRITE_TOOLS_IN_MANIFEST

    expect(both).to be_empty,
      "Tools listed in BOTH coverage and allowlist: #{both.inspect}. " \
      "Once a cassette exists, remove the allowlist entry."

    expect(missing).to be_empty,
      "Write-tools without cassette and not in allowlist: #{missing.inspect}. " \
      "Either record a cassette (preferred) or add an allowlist entry with a reason."

    expect(extra).to be_empty,
      "Stale entries (tools not in manifest.json): #{extra.inspect}."
  end

  it "every cassette path in coverage map exists on disk" do
    missing_files = []
    COVERAGE_MAP.each do |tool, paths|
      Array(paths).each do |path|
        full = File.join(REPO_ROOT, path)
        missing_files << "#{tool}: #{path}" unless File.exist?(full)
      end
    end
    expect(missing_files).to be_empty,
      "Coverage map references non-existing cassette(s): #{missing_files.join("; ")}"
  end

  it "every allowlist entry has a non-empty reason" do
    empty_reasons = ALLOWLIST.select { |_, entry| entry["reason"].to_s.strip.empty? }
    expect(empty_reasons.keys).to be_empty,
      "Allowlist entries missing a reason: #{empty_reasons.keys.inspect}"
  end
end
