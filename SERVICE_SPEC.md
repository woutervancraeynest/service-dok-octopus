# Dok Service Specification

> Complete technical reference for building a Dok-compatible service.
> Version: 1.0

## Overview

A Dok Service is a **Docker container** running an HTTP server that exposes tools to AI agents. Dok proxies tool calls from its MCP (Model Context Protocol) layer to your container via a simple JSON-over-HTTP contract. Your service declares its capabilities in a **manifest** (JSON), and Dok handles discovery, lifecycle management, OAuth brokering, and tool routing.

**Your service needs just 2 HTTP endpoints:** `/health` and `/call`.

---

## 1. Manifest Schema

The manifest is a JSON object entered in the Dok admin panel when registering a service. It defines your service's tools, OAuth requirements, and runtime configuration.

**Max size: 100KB.**

### Full Schema

```json
{
  "tools": [
    {
      "name": "tool_slug",
      "description": "Human-readable description of what this tool does",
      "input_schema": {
        "type": "object",
        "properties": {
          "param_name": {
            "type": "string",
            "description": "What this parameter is for"
          },
          "another_param": {
            "type": "integer",
            "description": "Some number"
          }
        },
        "required": ["param_name"]
      },
      "annotations": {
        "read_only_hint": true,
        "destructive_hint": false,
        "idempotent_hint": true
      }
    }
  ],
  "oauth": {
    "required": true,
    "provider": "provider-name"
  },
  "configuration": {
    "field_key": {
      "label": "Human Label",
      "type": "text",
      "placeholder": "Example value",
      "description": "Help text for the user"
    }
  },
  "runtime": {
    "port": 8080,
    "health_check": "/health"
  }
}
```

### Field Reference

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `tools` | `Array<Object>` | No | `[]` | Tool definitions |
| `tools[].name` | `string` | **Yes** | — | Slug identifier. Becomes `{service-name}.{tool-name}` in MCP |
| `tools[].description` | `string` | No | `"Tool from {display_name}"` | Human-readable description shown to the AI |
| `tools[].input_schema` | `object` | No | `{type: "object", properties: {}}` | JSON Schema for tool parameters |
| `tools[].annotations.read_only_hint` | `boolean` | No | `false` | Tool only reads data |
| `tools[].annotations.destructive_hint` | `boolean` | No | `false` | Tool may destroy data |
| `tools[].annotations.idempotent_hint` | `boolean` | No | `false` | Safe to retry |
| `oauth` | `object` | No | — | OAuth configuration |
| `oauth.required` | `boolean` | No | — | If `true`, `oauth.provider` must be set |
| `oauth.provider` | `string` | Conditional | — | Provider identifier (e.g. `"google"`, `"octopus"`) |
| `configuration` | `object` | No | `{}` | Per-project config fields shown in settings UI |
| `configuration.{key}.label` | `string` | No | Humanized key | Form label |
| `configuration.{key}.type` | `string` | No | `"text"` | `"text"`, `"textarea"`, or `"select"` |
| `configuration.{key}.options` | `array` | No | — | Options for `"select"` type |
| `configuration.{key}.placeholder` | `string` | No | — | Placeholder text |
| `configuration.{key}.description` | `string` | No | — | Help text |
| `runtime.port` | `integer` | No | `8080` | Port your app listens on inside the container |
| `runtime.health_check` | `string` | No | `"/health"` | Health check endpoint path |

### Validation Rules

1. Manifest must be a JSON object
2. Max size: 100KB serialized
3. If `tools` is present, it must be an array of objects each with a non-empty `name`
4. If `oauth.required` is `true`, then `oauth.provider` must be present

---

## 2. HTTP Contract: Tool Calls

### Request (Dok → Your Service)

```
POST http://localhost:{assigned_port}/call
Content-Type: application/json
```

No authentication headers. Communication is over Docker's internal network.

#### Request Body

```json
{
  "tool": "list_invoices",
  "params": {
    "status": "pending",
    "limit": 10
  },
  "context": {
    "project_id": 42,
    "project_name": "my-project",
    "oauth_tokens": {
      "access_token": "ya29.a0AfH6SM...",
      "refresh_token": "1//0dx...",
      "token_type": "Bearer",
      "expires_in": 3600
    },
    "configuration": {
      "api_endpoint": "https://api.example.com"
    }
  }
}
```

| Field | Type | Always Present | Description |
|---|---|---|---|
| `tool` | `string` | Yes | The raw tool name from your manifest (e.g. `"list_invoices"`, NOT `"service-name.list_invoices"`) |
| `params` | `object` | Yes | Parameters from the AI, matching your `input_schema` |
| `context.project_id` | `integer` | Yes | Dok's internal project ID |
| `context.project_name` | `string` | Yes | The project slug |
| `context.oauth_tokens` | `object` | Yes | `{}` if no OAuth. Contains tokens when connected |
| `context.configuration` | `object` | Yes | `{}` by default. Per-project config from settings |

#### Timeouts

| Timeout | Value |
|---|---|
| Connection timeout | 5 seconds |
| Read timeout | 30 seconds |

### Response (Your Service → Dok)

**Status:** `200 OK` — any other status is treated as an error.

**Body:** Valid JSON. The entire response is parsed and forwarded to the AI agent.

```json
{
  "invoices": [
    {"id": 1, "customer": "Acme", "amount": 100.00, "status": "paid"},
    {"id": 2, "customer": "Globex", "amount": 250.00, "status": "pending"}
  ],
  "total": 2
}
```

For application-level errors, return HTTP 200 with an error object:

```json
{"error": "Invoice not found", "code": "NOT_FOUND"}
```

### Error Conditions Detected by Dok

| Condition | Error Message to AI |
|---|---|
| Container not running | `"Service '{name}' is not running"` |
| Invalid port | `"Service '{name}' has an invalid port configuration"` |
| Connection refused | `"Service '{name}' is not reachable"` |
| Timeout | `"Service '{name}' timed out: {message}"` |
| Non-200 HTTP | `"Service returned HTTP {code}: {body truncated}"` |
| Invalid JSON | `"Invalid response from service: {error}"` |

---

## 3. Health Check

### Request

```
GET http://localhost:{assigned_port}/health
```

### Expected Response

HTTP `200` — body is ignored.

### Behavior

- Dok polls **once per second** for up to **30 seconds** after container start
- If all 30 attempts fail, the service is marked as error
- Connection refused, timeout, or non-200 all count as failure

---

## 4. Docker Requirements

### Repository Structure

```
/
├── Dockerfile          ← REQUIRED at repo root
├── manifest.json       ← For reference (entered in admin UI)
├── Gemfile             ← Dependencies
├── app.rb              ← Your application
└── ...
```

### Build Process

1. Dok clones: `git clone --depth 1 --branch {version} {git_url}`
2. Dok builds: `docker build -t dok-svc-{name}:{version} .`

The `version` field is used as the git **branch or tag**.

### Container Limits

| Resource | Limit |
|---|---|
| CPU | 0.5 vCPU |
| Memory | 256 MB |
| PIDs | 64 |
| Restart policy | `unless-stopped` |
| Network | `dok-services` (bridge) |
| Container name | `dok-svc-{service-name}` |

### Port Mapping

- Your app listens on `runtime.port` (default `8080`) **inside** the container
- Dok assigns a **host port** from `8000–8999` and maps it
- You do NOT choose the host port

---

## 5. Environment Variables

Your container receives these env vars at runtime:

| Variable | Always | Description |
|---|---|---|
| `SERVICE_NAME` | Yes | The service slug (e.g. `"octopus-accounting"`) |
| `PORT` | Yes | Port to listen on (matches `runtime.port`, default `8080`) |
| `OAUTH_CLIENT_ID` | If OAuth | Platform-level OAuth client ID |
| `OAUTH_CLIENT_SECRET` | If OAuth | Platform-level OAuth client secret |

**Per-project OAuth user tokens** (access_token, refresh_token) are NOT env vars — they arrive in `context.oauth_tokens` on each `/call` request.

---

## 6. OAuth Flow

If your manifest declares `oauth.required: true`:

### What Happens

1. User clicks "Authorize" in project settings
2. Dok redirects to the provider's authorization URL
3. Provider redirects back to Dok with an authorization code
4. Dok exchanges the code for tokens and stores them encrypted per project

### What Your Service Receives

On each `/call`, `context.oauth_tokens` contains the raw token response:

```json
{
  "access_token": "ya29.a0AfH6SM...",
  "refresh_token": "1//0dx...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

### Your Responsibilities

- Use `access_token` to call the external API
- Handle token refresh if expired (using `refresh_token` + `OAUTH_CLIENT_ID` / `OAUTH_CLIENT_SECRET` env vars)
- Return clear error messages if not authenticated

---

## 7. Service Registration

When registering in the Dok admin panel:

| Field | Required | Validation | Example |
|---|---|---|---|
| Slug | Yes | Unique, `[a-z0-9-]+` | `octopus-accounting` |
| Display Name | Yes | — | `Octopus Accounting` |
| Description | Yes | — | `Sync invoices from Octopus` |
| Git URL | Yes | HTTPS only | `https://github.com/org/repo` |
| Version | Yes | Used as git tag/branch | `1.0.0` or `main` |
| Author | Yes | — | `Your Name` |
| Manifest | No | See §1 | `{"tools": [...]}` |

### Lifecycle

```
draft → review → approved → published → deprecated
```

Only **published** services with a running container expose tools to AI agents.

---

## 8. Constraints Summary

| Constraint | Value |
|---|---|
| Container memory | 256 MB |
| Container CPU | 0.5 vCPU |
| Max PIDs | 64 |
| Host port range | 8000–8999 |
| Internal port default | 8080 |
| Health check timeout | 30s (1 poll/sec) |
| Tool call timeout | 30s read, 5s connect |
| Manifest max size | 100 KB |
| Name format | `[a-z0-9]([a-z0-9-]*[a-z0-9])?` |
| Git URL | HTTPS only |
| Response format | JSON |
| Docker network | `dok-services` (bridge) |
