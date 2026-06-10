# Shared error handling for MCP write-tools that call the Octopus API.
#
# Wrap any client.* call that performs a write (POST/PUT/DELETE) with
# `with_write_logging` so that, on failure, the body that was sent and the
# Octopus error message both end up in the response hash AND on stderr. This
# makes diagnosing API mismatches dramatically easier than the historical
# pattern where the sent body was discarded and only a generic "Octopus API
# error" survived.
#
# Usage:
#
#   module Tools
#     class MyTool
#       extend OctopusAuth
#       extend WriteLogging
#
#       def self.call(params:, context:)
#         body = build_body(params)
#         with_dossier_connection(context) do |client|
#           with_write_logging(name: "my_tool", body: body) do
#             client.do_something(body)
#             { status: "ok", message: "..." }
#           end
#         end
#       end
#     end
#   end
#
# The block's return hash is augmented with `sent_body: body` on success.
# On `OctopusClient::ApiError`, the helper returns
#   { error: "...", sent_body: body }
# AND logs both to stderr.
#
module Tools
  module WriteLogging
    # Wrap a write call against the Octopus client.
    #
    # name:     identifier used in stderr logs (e.g. "insert_balancing").
    # body:     the request body being sent — included in the response and stderr.
    # on_error: optional lambda/proc called when an ApiError is raised. It
    #           receives (error_hash, exception) and may return an updated
    #           hash. Use this for tool-specific diagnostic enrichment (e.g.
    #           detecting conflicts via additional API calls).
    def with_write_logging(name:, body:, on_error: nil)
      payload = yield
      payload.merge(sent_body: body)
    rescue OctopusClient::ApiError => e
      $stderr.puts "[#{name}] Octopus rejected request"
      $stderr.puts "[#{name}] body: #{body.to_json}"
      $stderr.puts "[#{name}] error: #{e.message}"
      result = { error: "Octopus API error: #{e.message}", sent_body: body }
      result = on_error.call(result, e) if on_error
      result
    end
  end
end
