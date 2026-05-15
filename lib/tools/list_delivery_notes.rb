# Get delivery notes from the configured Octopus dossier.
#
# Can filter by bookyear, journal, and document number. Returns delivery note
# details including relation, lines, and dates.
#
module Tools
  class ListDeliveryNotes
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        result = client.get_delivery_notes(
          bookyear_key_id: params["bookyear_id"],
          journal_key: params["journal_key"],
          document_sequence_nr: params["document_sequence_nr"]
        )

        return { delivery_notes: [], total: 0 } if result.nil? || result.empty?

        notes = result.is_a?(Array) ? result : [result]

        {
          delivery_notes: notes,
          total: notes.length
        }
      end
    end
  end
end
