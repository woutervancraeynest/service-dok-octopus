require "json"
require "json_schemer"

# OctopusSchemaHelper — validates request bodies against the official Octopus
# REST API OpenAPI schema.
#
# Usage in specs:
#
#   require_relative "../support/octopus_schema_helper"
#
#   expect(captured_body).to match_octopus_schema("BalancingServiceData")
#
# The matcher uses the snapshot at docs/octopus_openapi_v51.9.17.json. To
# upgrade, replace that file with a fresh download from
# https://service.inaras.be/octopus-rest-api/v1/openapi.json
# and update the filename in this helper + the docs reference in CLAUDE.md.
#
module OctopusSchemaHelper
  SNAPSHOT_PATH = File.expand_path(
    "../../docs/octopus_openapi_v51.9.17.json",
    __dir__
  )

  class << self
    # Returns the parsed snapshot (cached).
    def spec
      @spec ||= JSON.parse(File.read(SNAPSHOT_PATH))
    end

    # Returns the schema definition for a named component.
    def schema_for(name)
      schema = spec.dig("components", "schemas", name)
      raise ArgumentError, "Unknown Octopus schema: #{name.inspect}" unless schema
      schema
    end

    # Build a JSONSchemer for a named component.
    #
    # We wrap the target in a document that carries the full `components`
    # block, so $ref's like "#/components/schemas/BookyearKey" resolve
    # against the wrapper.
    #
    # When strict=true we recursively inject additionalProperties: false into
    # every nested object schema, so that unknown fields fail validation.
    # This catches bugs like "field renamed but tool still sends old name".
    # OpenAPI 3.0 by default ALLOWS additional properties; the strict variant
    # is opinionated for our use case (we want our tools to send exactly what
    # the schema declares).
    def schemer_for(name, strict: false)
      schema_for(name) # raises if name unknown
      key = [name, strict]
      @schemers ||= {}
      @schemers[key] ||= begin
        components = strict ? components_with_strict_props : spec["components"]
        JSONSchemer.schema(
          {
            "$ref" => "#/components/schemas/#{name}",
            "components" => components
          }
        )
      end
    end

    # Returns true if the body matches the schema. By default strict (no
    # unknown fields). Pass strict: false to allow extras.
    def valid?(body, schema_name, strict: true)
      schemer_for(schema_name, strict: strict).valid?(body)
    end

    # Returns a human-readable error list for a failing body.
    def errors(body, schema_name, strict: true)
      schemer_for(schema_name, strict: strict).validate(body).map do |err|
        path = err["data_pointer"].to_s.empty? ? "<root>" : err["data_pointer"]
        "  - at #{path}: #{err["error"]}"
      end
    end

    private

    # Build a copy of spec["components"] where every object-typed schema has
    # additionalProperties: false (unless it already has additionalProperties).
    def components_with_strict_props
      @strict_components ||= deep_strict(spec["components"])
    end

    def deep_strict(node)
      case node
      when Hash
        out = node.each_with_object({}) { |(k, v), h| h[k] = deep_strict(v) }
        # If this looks like an object schema (has properties or type=object)
        # and doesn't already declare additionalProperties, lock it down.
        if (out["type"] == "object" || out.key?("properties")) && !out.key?("additionalProperties")
          out["additionalProperties"] = false
        end
        out
      when Array
        node.map { |x| deep_strict(x) }
      else
        node
      end
    end
  end
end

RSpec::Matchers.define :match_octopus_schema do |schema_name|
  match do |body|
    OctopusSchemaHelper.valid?(body, schema_name, strict: true)
  end

  failure_message do |body|
    errors = OctopusSchemaHelper.errors(body, schema_name, strict: true)
    "Body does not match Octopus schema #{schema_name} (strict, no unknown fields):\n" \
      "#{errors.join("\n")}\n" \
      "Body sent:\n#{JSON.pretty_generate(body)}"
  end

  description { "match Octopus schema #{schema_name}" }
end
