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
# Rate limit: 400 calls/day.
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
        with_write_logging(name: "insert_balancing", body: balancing_data) do
          client.insert_balancing(balancing_data)
          { status: "created", message: "Balancing inserted successfully." }
        end
      end
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
