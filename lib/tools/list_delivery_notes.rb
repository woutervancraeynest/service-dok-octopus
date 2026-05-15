# Get delivery notes from the configured Octopus dossier.
#
# Can filter by bookyear, journal, and document number. Returns delivery note
# details including relation, lines, and dates.
#
# Fallback: if the standard endpoint returns HTTP 400, falls back to the
# /modified endpoint which is more reliable.
#
module Tools
  class ListDeliveryNotes
    extend OctopusAuth

    def self.call(params:, context:)
      with_dossier_connection(context) do |client|
        notes = begin
          client.get_delivery_notes(
            bookyear_key_id: params["bookyear_id"],
            journal_key: params["journal_key"],
            document_sequence_nr: params["document_sequence_nr"]
          )
        rescue OctopusClient::ApiError => e
          raise unless e.message.include?("HTTP 400")

          # Fallback to /modified endpoint
          client.get_modified_delivery_notes(
            bookyear_id: params["bookyear_id"] || -1,
            journal_key: params["journal_key"],
            modified_timestamp: "2000-01-01 00:00:00.000"
          )
        end

        return { delivery_notes: [], total: 0 } if notes.nil? || notes.empty?

        result = notes.is_a?(Array) ? notes : [notes]

        # Filter by document_sequence_nr if specified (modified endpoint returns all)
        if params["document_sequence_nr"]
          doc_nr = params["document_sequence_nr"].to_i
          result = result.select { |n| n["documentSequenceNr"] == doc_nr }
        end

        {
          delivery_notes: result,
          total: result.length
        }
      end
    end
  end
end
