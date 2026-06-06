require_relative "integration_helper"

# Integration test for update_financial_divers_booking.
#
# Regression test for the bug where the tool sent `periodNr` instead of
# `bookyearPeriodeNr` and omitted `exchangeRate`, causing every update to
# fail with a misleading "periode niet toegankelijk" error.
#
# The test performs a NO-OP update on an existing F1 booking in the sandbox
# dossier (49555, bookyear 1). It first reads the current state of the
# booking, then sends an update with the exact same data — proving the
# wire format is now accepted by Octopus.
#
RSpec.describe "Update Financial Divers Booking integration", :integration do
  it "successfully updates a CODA-imported bank booking with the corrected body shape",
     vcr_cassette: "write_tools/update_financial_divers_booking_noop" do
    client = integration_client
    client.authenticate
    client.connect_dossier(OCTOPUS_DOSSIER_ID)

    # Read the current state of an existing F1 booking.
    bookings = client.get_financial_divers_bookings(
      bookyear_key_id: 1, journal_key: "F1"
    )
    skip "No F1 bookings in sandbox" if bookings.nil? || bookings.empty?

    target = bookings.first
    target_seq = target["documentSequenceNr"]
    target_period = target["bookyearPeriodeNr"]
    target_date = target["documentDate"]
    target_lines = target["bookingLines"].map do |line|
      out = { "type" => line["type"], "amount" => line["amount"] }
      out["account_key"]  = line["accountKey"]  if line["accountKey"] && line["accountKey"] != 0
      out["relation_id"]  = line["relationId"]  if line["relationId"] && line["relationId"] != 0
      out["reference"]    = line["reference"]   if line["reference"] && !line["reference"].empty?
      out
    end

    # Send a no-op update via the MCP tool.
    result = Tools::UpdateFinancialDiversBooking.call(
      params: {
        "bookyear_id"          => 1,
        "journal_key"          => "F1",
        "document_sequence_nr" => target_seq,
        "period_nr"            => target_period,
        "document_date"        => target_date,
        "exchange_rate"        => target["exchangeRate"] || 1.0,
        "booking_lines"        => target_lines
      },
      context: integration_context
    )

    expect(result).not_to have_key(:error),
      "update failed: #{result[:error]} (body sent: #{result[:sent_body].inspect})"
    expect(result[:status]).to eq("updated")
  end
end
