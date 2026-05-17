# service-dok-octopus

Dok MCP (Model Context Protocol) service for the [Octopus](https://www.octopus.be) Belgian accounting software. Acts as a bridge between AI agents (via Dok's MCP proxy) and the Octopus REST API.

## Architecture

```
Dok Agent  →  Dok MCP Proxy  →  This Service (Sinatra)  →  Octopus REST API
                                      ↓
                              octopus_client gem
                              (vendor/octopus_client)
```

The service exposes accounting tools that AI agents can call via the MCP protocol. Each tool maps to one or more Octopus API endpoints, with the `octopus_client` gem handling authentication, error recovery, and API quirks.

## Quick Start

```bash
bundle install
bundle exec ruby app.rb       # Start on port 8080
curl http://localhost:8080/health  # => OK
```

## Configuration

The service expects Octopus credentials in the MCP request context:

```json
{
  "tool": "list_dossiers",
  "params": {},
  "context": {
    "configuration": {
      "octopus_user": "user@D05000000",
      "octopus_password": "password",
      "software_house_id": "uuid-here",
      "dossier_id": "49555"
    }
  }
}
```

These are configured in the Dok service settings, not in environment variables.

## Available Tools (57)

### Read Tools

| Tool | Description | Params |
|------|-------------|--------|
| `list_dossiers` | List accessible dossiers | — |
| `get_bookyears` | Get all bookyears | — |
| `get_bookyear` | Get single bookyear | `bookyear_id` |
| `get_api_version` | API version (no auth needed) | — |
| `list_relations` | All clients/suppliers | — |
| `list_accounts` | Chart of accounts | `bookyear_id` |
| `list_journals` | All journals for a bookyear | `bookyear_id` |
| `list_buy_sell_bookings` | Buy/sell bookings | `bookyear_id?`, `journal_key?`, `document_sequence_nr?` |
| `list_invoices` | Invoices | `bookyear_id?`, `journal_key?`, `document_sequence_nr?` |
| `list_financial_divers_bookings` | Financial/divers bookings | `bookyear_id?`, `journal_key?`, `document_sequence_nr?` |
| `list_delivery_notes` | Delivery notes | `bookyear_id?`, `journal_key?`, `document_sequence_nr?` |
| `get_journal_entry` | Single journal entry | `bookyear_id`, `journal_type`, `sequence_number` |
| `get_financial_journal_balance` | Journal balance | `bookyear_id`, `journal_key` |
| `get_cost_centres` | All cost centres | — |
| `get_active_cost_centres` | Active cost centres | — |
| `get_products` | All products | — |
| `get_product_groups` | Product groups | — |
| `get_vat_codes` | VAT codes | — |
| `get_currencies` | Currencies | — |
| `get_custom_fields` | Custom fields | — |
| `get_payment_list` | Payment list | — |
| `get_unbalanced_invoices` | Unbalanced invoices | — |
| `get_envelopes` | Payment envelopes | — |
| `get_envelope_content` | Envelope details | `envelope_key_id` |
| `get_rappels` | Overdue reminders | `expiration_date` |
| `get_modified_balancings` | Recent balancings | `modified_timestamp?` |
| `get_invoice_delivery_states` | Invoice delivery status | `bookyear_id`, `journal_key?` |

### Report Tools

| Tool | Description | Params |
|------|-------------|--------|
| `report_open_clients` | Unpaid client invoices | `bookyear_id`, `to_bookyear_id?`, `period_from?`, `period_to?`, `journal_key?` |
| `report_open_suppliers` | Unpaid supplier invoices | _(same)_ |
| `report_open_accounts` | Unbalanced accounts | _(same)_ |
| `report_history_clients` | Client history | _(same)_ |
| `report_history_suppliers` | Supplier history | _(same)_ |
| `report_history_accounts` | Account history | _(same)_ |
| `report_history_cost_centres` | Cost centre history | _(same)_ |

### Export Tools

| Tool | Description | Params |
|------|-------------|--------|
| `export_invoice` | Export invoice (PDF) | `bookyear_id`, `journal_key`, `document_sequence_nr` |
| `export_delivery_note` | Export delivery note (PDF) | _(same)_ |
| `export_rappel` | Export reminder (PDF) | `relation_id`, `rappel_id` |
| `export_envelope` | Export envelope (SEPA) | `envelope_key_id` |

### Write Tools

| Tool | Description |
|------|-------------|
| `create_relation` | Create/update client or supplier |
| `create_buy_sell_booking` | Create buy/sell booking |
| `create_financial_divers_booking` | Create financial/divers booking |
| `create_invoice` | Create invoice |
| `create_delivery_note` | Create delivery note |
| `insert_balancing` | Match payment to invoice |
| `delete_balancing` | Undo payment matching |
| `create_or_update_account` | Upsert account |
| `create_or_update_cost_centre` | Upsert cost centre |
| `create_or_update_product` | Upsert product |
| `update_buy_sell_booking` | Update booking |
| `update_financial_divers_booking` | Update booking |
| `update_invoice` | Update invoice |
| `update_delivery_note` | Update delivery note |
| `generate_invoice` | Generate invoice PDF |
| `generate_delivery_note` | Generate delivery note PDF |
| `book_invoices` | Book invoices (make final) |
| `send_invoices` | Send invoices by email |
| Various banking/envelope tools | Payment list, envelopes |
| `create_bookyear` | Create new bookyear |
| `update_bookyear` | Update bookyear |
| `book_bookyear` | Book to next bookyear |

## Skills

The `skills/` directory contains instruction documents for AI agents:

- **`reconciliation.md`** — Payment reconciliation skill. Guides an agent through matching bank payments (F-journal) with invoices (A/V-journal) using a confidence-based approach: high-confidence matches are executed automatically, low-confidence matches are proposed to the bookkeeper.

## Vendor Dependencies

The `octopus_client` gem is vendored in `vendor/octopus_client/` rather than fetched from GitHub at deploy time. This ensures deterministic builds.

### Updating the vendor

When the gem is updated at [by2-be/octopus_client](https://github.com/by2-be/octopus_client):

```bash
# 1. Update the gem repo
cd ../octopus_client
git pull

# 2. Copy to vendor (exclude non-runtime files)
rm -rf vendor/octopus_client
cp -r ../octopus_client vendor/octopus_client
rm -rf vendor/octopus_client/.git
rm -rf vendor/octopus_client/spec
rm -rf vendor/octopus_client/.rspec
rm -rf vendor/octopus_client/Gemfile
rm -rf vendor/octopus_client/Gemfile.lock
rm -rf vendor/octopus_client/.gitignore

# 3. Verify
grep VERSION vendor/octopus_client/lib/octopus_client/version.rb
bundle install
bundle exec rspec

# 4. Commit
git add vendor/octopus_client
git commit -m "Update vendored octopus_client to vX.Y.Z"
```

### Why vendor instead of git source?

- **Deterministic deploys** — No git fetch needed at deploy time
- **Offline builds** — Works without network access to GitHub
- **Version pinning** — Explicit control over exactly which code is deployed
- **Spec files excluded** — Only runtime code (`lib/`) is vendored, keeping the deployment lean

## Testing

```bash
# Unit tests (300 tests)
bundle exec rspec

# Integration tests with VCR cassettes (15 tests)
bundle exec rspec spec/integration/ -O /dev/null

# All tests
bundle exec rspec && bundle exec rspec spec/integration/ -O /dev/null
```

### VCR Cassettes

Integration tests use [VCR](https://github.com/vcr/vcr) to record and replay HTTP interactions with the real Octopus API. Cassettes are stored in `spec/integration/cassettes/`.

**Recording new cassettes** requires Octopus credentials:

```bash
export OCTOPUS_SOFTWARE_HOUSE_ID="your-uuid"
export OCTOPUS_DOSSIER_ID="49555"
bundle exec rspec spec/integration/ -O /dev/null
```

Credentials are automatically sanitized in cassettes (tokens, passwords, Software House ID replaced with placeholders).

### Test Coverage

| Category | Tests | Coverage |
|----------|-------|----------|
| Unit tests (all 57 tools) | 300 | 100% |
| Integration tests (VCR) | 15 | Core flows |
| **Total** | **315** | — |

## Project Structure

```
app.rb                    # Sinatra application, tool registry
manifest.json             # MCP tool definitions (schema + descriptions)
lib/
  service.rb              # Sinatra routes (/health, /call)
  tools/
    concerns/
      octopus_auth.rb     # Shared auth mixin for all tools
    list_dossiers.rb      # One file per tool
    create_relation.rb
    ...
skills/
  reconciliation.md       # AI agent skill documents
vendor/
  octopus_client/         # Vendored gem (lib/ only)
spec/
  spec_helper.rb          # WebMock stubs, test helpers
  app_spec.rb             # HTTP endpoint tests
  tools/                  # Unit tests per tool
  integration/
    integration_helper.rb # VCR config, credential sanitization
    cassettes/            # Recorded HTTP interactions
```

## Docker

```bash
docker build -t service-dok-octopus .
docker run -p 8080:8080 service-dok-octopus
```

## License

Proprietary — by2.be
