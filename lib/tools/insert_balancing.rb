# Insert a balancing entry in the configured Octopus dossier.
#
# Balancing happens at LINE level: each side (debet + credit) points to a
# specific bookingLine within a document, not just to a document. The Octopus
# API expects a BalancingServiceData body:
#
#   {
#     "debetKey":  { "bookyearKey": {"id": int}, "journalKey": str, "documentSequenceNr": int, "lineSequenceNr": int },
#     "creditKey": { "bookyearKey": {"id": int}, "journalKey": str, "documentSequenceNr": int, "lineSequenceNr": int },
#     "balanceAmount": double
#   }
#
# The caller MUST decide which side is debet and which is credit. Convention:
#   - Customer payment (balancing type 'C'): sell invoice (V-journal)  = debet,
#                                            bank booking (F-journal)  = credit.
#   - Supplier/VISA payment (type 'S'):      bank booking (F-journal)  = debet,
#                                            buy invoice  (A/D-journal) = credit.
#
# `line_sequence_nr` defaults to -1 when omitted, which Octopus interprets as
# "the whole document" (used for invoice headers in V1/A1). For bank booking
# lines you must pass the actual line number.
#
# CONFLICT DIAGNOSTIC: When Octopus rejects the request, the tool performs
# a post-mortem check via get_modified_balancings to detect whether either
# target line is already touched by existing balancings. When found, the
# tool surfaces those existing balancings in the error response so the
# caller can understand WHY Octopus refused (most common cause: the line is
# already fully balanced against another document — typical when CODA has
# already matched a payment to a structured-communication invoice and the
# caller is trying to match it again to a duplicate invoice).
#
# Rate limit: 400 calls/day (plus 1 get_modified_balancings call per failed
# attempt for diagnostic).
#
module Tools
  class InsertBalancing
    extend OctopusAuth
    extend WriteLogging

    REQUIRED_KEY_FIELDS = %w[bookyear_id journal_key document_sequence_nr].freeze

    def self.call(params:, context:)
      error = validate_params(params)
      return { error: error } if error

      balancing_data = build_balancing_data(params)

      with_dossier_connection(context) do |client|
        diagnose = ->(err, _ex) { enrich_error_with_existing_balancings(err, client, balancing_data) }

        with_write_logging(name: "insert_balancing", body: balancing_data, on_error: diagnose) do
          client.insert_balancing(balancing_data)
          { status: "created", message: "Balancing inserted successfully." }
        end
      end
    end

    # On API failure, query Octopus for any existing balancings touching the
    # debet or credit line we attempted to use, and append them to the error
    # response. This turns "Octopus said no" into "Octopus said no AND here
    # are the conflicting balancings already on that line".
    def self.enrich_error_with_existing_balancings(err, client, body)
      conflicts = existing_balancings_for_target_lines(client, body)
      return err if conflicts.empty?

      summary = conflicts.map { |c| format_balancing_summary(c) }.join("\n  - ")
      err[:error] = err[:error] + "\n\n" \
        "Existing balancings on your target lines (this is likely WHY Octopus " \
        "refused). If the line is already fully balanced, you cannot add another " \
        "balancing without first deleting the existing one. If your target invoice " \
        "is a duplicate of an already-paid invoice, the duplicate should be " \
        "credited or corrected — not re-balanced.\n\n" \
        "  - #{summary}"
      err[:existing_balancings_on_target_lines] = conflicts
      err
    rescue OctopusClient::ApiError, Faraday::Error => e
      # Diagnostic must NEVER mask the original error.
      $stderr.puts "[insert_balancing] diagnostic lookup failed: #{e.class}: #{e.message}"
      err
    end

    # Return the existing BalancingDetailServiceData entries whose debet or
    # credit document key matches either side of the body we attempted to send.
    def self.existing_balancings_for_target_lines(client, body)
      mod = client.get_modified_balancings(modified_timestamp: "2000-01-01 00:00:00.000")
      list = (mod.is_a?(Hash) ? mod["modifiedBalancings"] : nil) || []

      target_keys = [body["debetKey"], body["creditKey"]].compact.map { |k| balancing_key_signature(k) }

      list.select do |entry|
        d = balancing_key_signature(entry.dig("debetDocument", "balancingKey"))
        c = balancing_key_signature(entry.dig("creditDocument", "balancingKey"))
        target_keys.include?(d) || target_keys.include?(c)
      end
    end

    # Normalize a BalancingKeyServiceData hash to a comparable tuple.
    # Returns nil for missing/incomplete keys.
    def self.balancing_key_signature(key)
      return nil unless key.is_a?(Hash)
      [
        key.dig("bookyearKey", "id"),
        key["journalKey"],
        key["documentSequenceNr"],
        key["lineSequenceNr"]
      ]
    end

    def self.format_balancing_summary(entry)
      d = entry["debetDocument"] || {}
      c = entry["creditDocument"] || {}
      dk = d["balancingKey"] || {}
      ck = c["balancingKey"] || {}
      amount = entry["creditBalancedBookingAmount"] || entry["debetBalancedBookingAmount"]
      type   = entry.dig("type", "type")
      relation = entry.dig("type", "relationKey", "id")
      "type=#{type} relation=#{relation}: " \
        "DEBET #{dk["journalKey"]}/##{dk["documentSequenceNr"]} L#{dk["lineSequenceNr"]} (BJ#{dk.dig("bookyearKey","id")}) " \
        "↔ CREDIT #{ck["journalKey"]}/##{ck["documentSequenceNr"]} L#{ck["lineSequenceNr"]} (BJ#{ck.dig("bookyearKey","id")}) " \
        "amount=#{amount}"
    end

    def self.validate_params(params)
      return "amount is required (the balancing amount, positive number)." if params["amount"].nil?
      return "amount must be > 0." unless params["amount"].to_f > 0

      %w[debet_key credit_key].each do |side|
        key = params[side]
        return "#{side} is required and must be an object." unless key.is_a?(Hash)

        missing = REQUIRED_KEY_FIELDS.select { |f| key[f].nil? || key[f].to_s.empty? }
        unless missing.empty?
          return "#{side} is missing: #{missing.join(", ")}."
        end
      end

      nil
    end

    def self.build_balancing_data(params)
      {
        "debetKey"      => build_key(params["debet_key"]),
        "creditKey"     => build_key(params["credit_key"]),
        "balanceAmount" => params["amount"].to_f
      }
    end

    def self.build_key(key)
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
