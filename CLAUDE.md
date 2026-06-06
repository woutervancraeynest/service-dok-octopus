# Dok Service Template

You are building a **Dok Service** — a small HTTP server that exposes tools to AI agents via Dok's Service Market.

## What is a Dok Service?

A Dok Service is a Docker container that:
1. Listens on a single HTTP port (default `8080`)
2. Responds to `GET /health` with `200 OK`
3. Responds to `POST /call` with tool results as JSON

That's it. Dok handles everything else: service discovery, user authentication (OAuth), container lifecycle, and routing tool calls from AI agents to your service.

## Architecture

```
AI Agent (Claude) → Dok (MCP proxy) → Your Service Container
                                         POST /call
                                         { tool, params, context }
```

The AI agent never talks to your service directly. Dok proxies tool calls and injects project context (OAuth tokens, configuration) into each request.

## Project Structure

```
.
├── CLAUDE.md           ← You are here
├── SERVICE_SPEC.md     ← Full technical specification (read if you need details)
├── Dockerfile          ← Container definition
├── Gemfile             ← Ruby dependencies
├── Gemfile.lock
├── config.ru           ← Rack config
├── manifest.json       ← Tool definitions (copy to Dok admin when registering)
├── app.rb              ← Main application entry point
├── lib/
│   ├── service.rb      ← Base service class with routing and dispatch
│   └── tools/          ← One file per tool
│       └── example_tool.rb
└── spec/
    ├── spec_helper.rb
    └── app_spec.rb     ← Tests for /health and /call
```

## How to Build a New Service

### Step 1: Define your tools

Edit `manifest.json` to declare the tools your service exposes. Each tool needs:
- `name` — a slug (e.g. `list_invoices`)
- `description` — what the AI sees (be specific and helpful)
- `input_schema` — JSON Schema for parameters

```json
{
  "tools": [
    {
      "name": "list_invoices",
      "description": "List invoices from the accounting system. Returns an array of invoices with id, customer, amount, status, and date.",
      "input_schema": {
        "type": "object",
        "properties": {
          "status": { "type": "string", "description": "Filter: all, paid, pending, overdue" }
        }
      },
      "annotations": { "read_only_hint": true }
    }
  ]
}
```

### Step 2: Implement tool handlers

Create a file in `lib/tools/` for each tool. Follow the pattern in `lib/tools/example_tool.rb`:

```ruby
module Tools
  class ListInvoices
    def self.call(params:, context:)
      access_token = context.dig("oauth_tokens", "access_token")
      return { error: "Not authenticated. Connect your account first." } unless access_token

      # Call the external API
      response = Faraday.get("https://api.example.com/invoices") do |req|
        req.headers["Authorization"] = "Bearer #{access_token}"
        req.params["status"] = params["status"] if params["status"]
      end

      JSON.parse(response.body)
    end
  end
end
```

### Step 3: Register the tool in app.rb

Add your tool to the `TOOLS` hash in `app.rb`:

```ruby
TOOLS = {
  "list_invoices" => Tools::ListInvoices,
  # add more tools here
}.freeze
```

### Step 4: Add dependencies

Add any API client gems to `Gemfile`, then run `bundle install`.

### Step 5: Test locally

```bash
# Run the service
bundle exec ruby app.rb

# Test health check
curl http://localhost:8080/health

# Test a tool call
curl -X POST http://localhost:8080/call \
  -H "Content-Type: application/json" \
  -d '{
    "tool": "list_invoices",
    "params": {"status": "pending"},
    "context": {
      "project_id": 1,
      "project_name": "test",
      "oauth_tokens": {"access_token": "test-token"},
      "configuration": {}
    }
  }'
```

### Step 6: Docker build & test

```bash
docker build -t my-service .
docker run -p 8080:8080 my-service

# Same curl commands as above, but now against the container
```

## The /call Contract

### Request (what Dok sends you)

```json
{
  "tool": "tool_name",
  "params": { "key": "value" },
  "context": {
    "project_id": 42,
    "project_name": "my-project",
    "oauth_tokens": { "access_token": "...", "refresh_token": "..." },
    "configuration": { "custom_key": "custom_value" }
  }
}
```

- `tool` — the tool name from your manifest (e.g. `"list_invoices"`, not `"service-name.list_invoices"`)
- `params` — parameters the AI provided, matching your `input_schema`
- `context.oauth_tokens` — empty `{}` if no OAuth, or contains tokens after user authorization
- `context.configuration` — per-project settings configured by the user

### Response (what you return)

HTTP `200` with any valid JSON body. This JSON is forwarded directly to the AI.

```json
{
  "invoices": [
    {"id": 1, "customer": "Acme", "amount": 100.00}
  ],
  "total": 1
}
```

For errors, return HTTP 200 with an error field:
```json
{"error": "Invoice not found"}
```

## OAuth

If your service requires OAuth:

1. Set `"oauth": {"required": true, "provider": "your-provider"}` in the manifest
2. On each `/call`, check `context.oauth_tokens.access_token`
3. If empty, return `{"error": "Not authenticated. Connect your account first."}`
4. If present, use it to call the external API
5. For token refresh, use `OAUTH_CLIENT_ID` and `OAUTH_CLIENT_SECRET` env vars

## Environment Variables

Your container receives:

| Variable | Description |
|---|---|
| `SERVICE_NAME` | Your service slug |
| `PORT` | Port to listen on (default `8080`) |
| `OAUTH_CLIENT_ID` | OAuth client ID (if OAuth required) |
| `OAUTH_CLIENT_SECRET` | OAuth client secret (if OAuth required) |

## Constraints

| Constraint | Value |
|---|---|
| Memory | 256 MB |
| CPU | 0.5 vCPU |
| Tool call timeout | 30 seconds |
| Health check timeout | 30 seconds (1 poll/sec) |
| Response format | JSON |
| Max manifest size | 100 KB |

## Octopus API schema reference

Two sources of truth for the Octopus REST API contract:

- **Live**: `https://service.inaras.be/octopus-rest-api/v1/openapi.json`
- **Pinned snapshot in this repo**: `docs/octopus_openapi_v51.9.17.json`
  (used by the schema conformance audit; replace when upgrading the API)

**Consult the snapshot first** when:
- Adding a new write-tool — to know the exact endpoint, HTTP method,
  request schema name, and required fields.
- Debugging an unexpected HTTP 400 from Octopus — the schema almost always
  reveals the body-shape mismatch faster than reading the gem source.

How to find what a tool should send:
1. Identify the gem method the tool calls (in `vendor/octopus_client/lib/octopus_client/resources/`).
2. Note the endpoint and HTTP method in the gem comment (e.g. `# PUT /dossiers/{dossierId}/financialdiversbookings`).
3. Look up that endpoint in the snapshot (`docs/octopus_openapi_v51.9.17.json`).
4. The `requestBody.content.application/json.schema.$ref` is the schema name.
5. The full schema is under `components.schemas.<Name>` — required fields,
   property names, nested object structures.

## Schema conformance audit

`spec/audit/schema_conformance_spec.rb` runs on every `bundle exec rspec` and
enforces that each write-tool's wire body matches its target OpenAPI schema
(strict mode: missing required fields AND unknown extra fields both fail).

The mapping lives in `spec/audit/tool_schema_map.yml`. When you add a new
write-tool to `manifest.json`, you MUST add an entry here too — the audit
will fail otherwise.

Tools whose body shape currently doesn't match the schema are marked
`pending: true` with a `pending_reason: |` explaining the mismatch. Treat
pendings as TODO debt and resolve them when touching the tool.

## Cassette coverage policy

Every write-tool requires at least one VCR integration cassette against
the real Octopus sandbox API. The cassette proves the body shape that
schema validation accepts is also what the API actually accepts.

`spec/audit/cassette_coverage_spec.rb` enforces this:
- `spec/audit/tool_cassette_coverage.yml` maps tool → cassette path(s).
- `spec/audit/cassette_gap_allowlist.yml` lists known gaps with a `reason:`.

A new write-tool that's in neither file fails the audit. When recording a
new cassette, move the entry from the gap allowlist to the coverage map.

## Write-tool error logging convention

Every write-tool should call its client write method inside `with_write_logging`
from `lib/tools/concerns/write_logging.rb`. This guarantees that on failure,
the sent body and the Octopus error message both reach the caller AND
stderr. See `lib/tools/insert_balancing.rb` for the canonical example.

## Skill verification metadata

Files under `skills/` are read by AI agents at runtime. Each skill file
SHOULD start with a YAML frontmatter block declaring whether its claims
have been verified against the live API, and how:

```yaml
---
verified_against_api: true
verified_date: 2025-06-06
verified_against_api_version: "51.9.17"
verified_via:
  - spec/integration/some_spec.rb
notes: |
  Optional context about what was confirmed.
---
```

Skills with `verified_against_api: false` should explain in `notes:` what
remains unverified. Do NOT make assertive claims about API behavior in
skill files without verification — the LLM will trust the skill, and an
incorrect skill silently produces incorrect tool calls.

## Checklist Before Submitting

- [ ] `GET /health` returns 200
- [ ] `POST /call` returns valid JSON for each declared tool
- [ ] `POST /call` with unknown tool returns `{"error": "Unknown tool: ..."}`
- [ ] Tools handle missing OAuth tokens gracefully
- [ ] `docker build .` succeeds
- [ ] Container starts and passes health check within 30 seconds
- [ ] `manifest.json` matches your actual tool implementations
- [ ] Tool descriptions are clear and specific (the AI uses them to decide when to call your tool)
- [ ] Tests pass: `bundle exec rspec`
- [ ] New write-tools: schema conformance audit entry added (`spec/audit/tool_schema_map.yml`)
- [ ] New write-tools: VCR cassette recorded (or explicit allowlist entry with `reason:`)
- [ ] New write-tools: use `with_write_logging` helper
- [ ] New skills: frontmatter declares `verified_against_api: true/false`

## Testing

### Unit tests (fast, no network)

```bash
bundle exec rspec
```

Runs 128 unit tests with WebMock stubs. No network access needed.

### Integration tests (VCR, real Octopus sandbox API)

```bash
# First time: set credentials to record cassettes
export OCTOPUS_USER="bybe27@D05000000"
export OCTOPUS_PASSWORD="bybe27"
export OCTOPUS_SOFTWARE_HOUSE_ID="your-uuid-here"
export OCTOPUS_DOSSIER_ID="your-dossier-id"

# Run integration tests (records cassettes on first run)
bundle exec rspec spec/integration/ -O /dev/null --format documentation

# After cassettes are recorded, credentials are no longer needed
# Tests replay from cassettes automatically
```

Integration tests are **excluded by default** from `bundle exec rspec` (configured in `.rspec`).
Without credentials and cassettes, they show as `pending` — not failing.

### Re-recording cassettes

```bash
# Delete existing cassettes
rm -rf spec/integration/cassettes/**/*.yml

# Run with credentials to re-record
bundle exec rspec spec/integration/ -O /dev/null
```

## Full Specification

See `SERVICE_SPEC.md` for the complete technical reference including manifest schema details, all error conditions, Docker networking, and OAuth flow details.
