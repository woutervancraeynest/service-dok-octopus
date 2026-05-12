# Get a specific journal entry from the configured Octopus dossier.
#
# This tool combines multiple journal types into one interface. Based on the
# journal_type parameter, it calls the appropriate method:
# - "A" = Buy journal (Aankoop)
# - "V" = Sell journal (Verkoop)
# - "F" = Financial journal (Financieel)
# - "D" = Divers journal (Diversen)
# - "L" = Delivery journal (Leveringsbonnen)
#
module Tools
  class GetJournalEntry
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id journal_type sequence_number].freeze
    VALID_JOURNAL_TYPES = %w[A V F D L].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide bookyear_id, journal_type, and sequence_number." }
      end

      journal_type = params["journal_type"].to_s.upcase
      unless VALID_JOURNAL_TYPES.include?(journal_type)
        return { error: "Invalid journal_type: #{journal_type}. Must be one of: #{VALID_JOURNAL_TYPES.join(", ")}." }
      end

      with_dossier_connection(context) do |client|
        bookyear_id = params["bookyear_id"].to_i
        sequence_number = params["sequence_number"].to_i

        result = case journal_type
                 when "A"
                   client.get_buy_journal(bookyear_id: bookyear_id, sequence_number: sequence_number)
                 when "V"
                   client.get_sell_journal(bookyear_id: bookyear_id, sequence_number: sequence_number)
                 when "F"
                   client.get_financial_journal(bookyear_id: bookyear_id, sequence_number: sequence_number)
                 when "D"
                   client.get_divers_journal(bookyear_id: bookyear_id, sequence_number: sequence_number)
                 when "L"
                   client.get_delivery_journal(bookyear_id: bookyear_id, sequence_number: sequence_number)
                 end

        {
          journal_entry: result
        }
      end
    end
  end
end