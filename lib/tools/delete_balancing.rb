# Delete a balancing entry in the configured Octopus dossier.
#
# Removes a previously created balancing (payment-to-invoice match).
# Use this to undo an incorrect reconciliation.
#
# Three modes, each with a different body schema (per the official Octopus API):
#
#   mode 'item'        — Delete a specific balancing identified by its two
#                        BalancingKeys (debet + credit, both with lineSequenceNr).
#                        Body: DeleteBalancingItemRequest = { debetKey, creditKey }
#                        Both keys required.
#
#   mode 'bookingline' — Delete ALL balancings for one booking line.
#                        Body: BalancingKeyServiceData
#                        = { bookyearKey, journalKey, documentSequenceNr, lineSequenceNr }
#
#   mode 'document'    — Delete ALL balancings for one document (all its lines).
#                        Body: DocumentKeyServiceData
#                        = { bookyearKey, journal, documentSequenceNr }
#                        Note: this schema uses `journal`, NOT `journalKey`.
#
# Rate limit: 400 calls/day.
#
module Tools
  class DeleteBalancing
    extend OctopusAuth

    VALID_MODES = %w[item bookingline document].freeze
    REQUIRED_KEY_FIELDS = %w[bookyear_id journal_key document_sequence_nr].freeze

    def self.call(params:, context:)
      mode = params["mode"] || "item"

      unless VALID_MODES.include?(mode)
        return { error: "Invalid mode: #{mode}. Use 'item', 'bookingline', or 'document'." }
      end

      error, body = build_request(mode, params)
      return { error: error } if error

      with_dossier_connection(context) do |client|
        begin
          case mode
          when "item"        then client.delete_balancing(body)
          when "bookingline" then client.delete_balancing_by_bookingline(body)
          when "document"    then client.delete_balancing_by_document(body)
          end

          {
            status: "deleted",
            message: "Balancing deleted successfully (mode: #{mode}).",
            sent_body: body
          }
        rescue OctopusClient::ApiError => e
          $stderr.puts "[delete_balancing/#{mode}] Octopus rejected request"
          $stderr.puts "[delete_balancing/#{mode}] body: #{body.to_json}"
          $stderr.puts "[delete_balancing/#{mode}] error: #{e.message}"
          {
            error: "Octopus API error: #{e.message}",
            sent_body: body
          }
        end
      end
    end

    # Returns [error_string_or_nil, body_hash_or_nil].
    def self.build_request(mode, params)
      case mode
      when "item"
        %w[debet_key credit_key].each do |side|
          key = params[side]
          return ["#{side} is required and must be an object.", nil] unless key.is_a?(Hash)
          missing = REQUIRED_KEY_FIELDS.select { |f| key[f].nil? || key[f].to_s.empty? }
          return ["#{side} is missing: #{missing.join(", ")}.", nil] unless missing.empty?
        end

        body = {
          "debetKey"  => build_balancing_key(params["debet_key"]),
          "creditKey" => build_balancing_key(params["credit_key"])
        }
        [nil, body]

      when "bookingline"
        missing = (REQUIRED_KEY_FIELDS + ["line_sequence_nr"]).select { |f| params[f].nil? || params[f].to_s.empty? }
        return ["Missing required fields for mode 'bookingline': #{missing.join(", ")}.", nil] unless missing.empty?

        body = build_balancing_key(params)
        [nil, body]

      when "document"
        missing = REQUIRED_KEY_FIELDS.select { |f| params[f].nil? || params[f].to_s.empty? }
        return ["Missing required fields for mode 'document': #{missing.join(", ")}.", nil] unless missing.empty?

        body = {
          "bookyearKey"        => { "id" => params["bookyear_id"].to_i },
          "journal"            => params["journal_key"],
          "documentSequenceNr" => params["document_sequence_nr"].to_i
        }
        [nil, body]
      end
    end

    # Build a BalancingKeyServiceData from a hash with keys:
    # bookyear_id, journal_key, document_sequence_nr, line_sequence_nr (optional, defaults to -1).
    def self.build_balancing_key(key)
      line_nr = key["line_sequence_nr"]
      {
        "bookyearKey"        => { "id" => key["bookyear_id"].to_i },
        "journalKey"         => key["journal_key"],
        "documentSequenceNr" => key["document_sequence_nr"].to_i,
        "lineSequenceNr"     => line_nr.nil? ? -1 : line_nr.to_i
      }
    end
  end
end
