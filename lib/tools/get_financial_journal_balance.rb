# Get the balance of a financial journal from the configured Octopus dossier.
#
# Returns the journal balance information for the specified bookyear and journal.
#
module Tools
  class GetFinancialJournalBalance
    extend OctopusAuth

    REQUIRED_PARAMS = %w[bookyear_id journal_key].freeze

    def self.call(params:, context:)
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? || params[k].to_s.strip.empty? }
      unless missing.empty?
        return { error: "Missing required parameters: #{missing.join(", ")}. Provide bookyear_id and journal_key." }
      end

      with_dossier_connection(context) do |client|
        result = client.get_financial_journal_balance(
          bookyear_id: params["bookyear_id"].to_i,
          journal_key: params["journal_key"]
        )

        {
          balance: result
        }
      end
    end
  end
end