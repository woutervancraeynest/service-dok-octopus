require_relative "integration_helper"

# Integration tests for balancing tools.
#
# These tests exercise the REAL Octopus API. Without credentials and recorded
# cassettes they are automatically skipped (see integration_helper.rb).
#
# ============================================================================
# Default test case (sandbox dossier 49555, bookyear 1)
# ============================================================================
# The default test case is a customer-type (C) balancing that ALREADY EXISTS in
# the sandbox demo dossier:
#   DEBET  : V1 / doc 1 / line -1  (sell invoice "Levering",  2544.00 EUR)
#   CREDIT : F1 / doc 2 / line  1  (bank booking "2010/V1/1", 2544.00 EUR)
#
# The round-trip test DELETES this balancing and RE-INSERTS it via our new
# tools, so the dossier ends up in the same state as before.
#
# ============================================================================
# Field test case (from bug report, production-only)
# ============================================================================
# To replay the original VISA-afpunting that triggered this fix, override:
#   BALANCING_BOOKYEAR_ID=10
#   BALANCING_DEBET_JOURNAL=F1   BALANCING_DEBET_DOC_SEQ=62  BALANCING_DEBET_LINE_SEQ=3
#   BALANCING_CREDIT_JOURNAL=D4  BALANCING_CREDIT_DOC_SEQ=2  BALANCING_CREDIT_LINE_SEQ=5
#   BALANCING_AMOUNT=495.48
#   OCTOPUS_DOSSIER_ID=<your-production-dossier>
#   KEEP_TEST_BALANCING=1     # leave the balancing in place if accounting-correct
#
# WARNING: insert_balancing creates a real balancing. The spec tries to clean
# up via delete_balancing afterwards unless KEEP_TEST_BALANCING is set.
#
RSpec.describe "Balancing Tools", :integration do
  # --- Test case data (override via env if needed) ----------------------------
  TESTCASE = {
    bookyear_id:               ENV.fetch("BALANCING_BOOKYEAR_ID",        "1").to_i,
    debet_journal:             ENV.fetch("BALANCING_DEBET_JOURNAL",      "V1"),
    debet_document_seq:        ENV.fetch("BALANCING_DEBET_DOC_SEQ",      "1").to_i,
    debet_line_seq:            ENV.fetch("BALANCING_DEBET_LINE_SEQ",     "-1").to_i,
    credit_journal:            ENV.fetch("BALANCING_CREDIT_JOURNAL",     "F1"),
    credit_document_seq:       ENV.fetch("BALANCING_CREDIT_DOC_SEQ",     "2").to_i,
    credit_line_seq:           ENV.fetch("BALANCING_CREDIT_LINE_SEQ",    "1").to_i,
    amount:                    ENV.fetch("BALANCING_AMOUNT",             "2544.0").to_f
  }.freeze

  def debet_key
    {
      "bookyear_id"          => TESTCASE[:bookyear_id],
      "journal_key"          => TESTCASE[:debet_journal],
      "document_sequence_nr" => TESTCASE[:debet_document_seq],
      "line_sequence_nr"     => TESTCASE[:debet_line_seq]
    }
  end

  def credit_key
    {
      "bookyear_id"          => TESTCASE[:bookyear_id],
      "journal_key"          => TESTCASE[:credit_journal],
      "document_sequence_nr" => TESTCASE[:credit_document_seq],
      "line_sequence_nr"     => TESTCASE[:credit_line_seq]
    }
  end

  # ---- get_modified_balancings (read-only) ---------------------------------

  describe "get_modified_balancings" do
    it "fetches modified balancings without error",
       vcr_cassette: "balancings/get_modified_balancings" do
      result = Tools::GetModifiedBalancings.call(
        params: { "modified_timestamp" => "2000-01-01 00:00:00.000" },
        context: integration_context
      )

      # 404 (no balancings yet) is a valid outcome and the tool returns
      # {balancings: [], total: 0}
      expect(result).not_to have_key(:error)
    end
  end

  # ---- delete + insert round-trip on an existing balancing -----------------
  #
  # This test works against EITHER state:
  #   - Default sandbox case: the balancing V1/#1 ↔ F1/#2 already exists.
  #     Flow: delete it, verify gone, re-insert it, verify back.
  #   - Fresh balancing (e.g. production VISA test): the balancing does NOT yet
  #     exist. The initial delete is then a no-op (handled gracefully), insert
  #     creates it, and (unless KEEP_TEST_BALANCING is set) the final delete
  #     removes it.
  #
  describe "delete + insert round-trip" do
    it "deletes any existing balancing, re-inserts it, and verifies the round-trip",
       vcr_cassette: "balancings/delete_and_insert_roundtrip" do
      # ---- STEP 1: delete (tolerate "doesn't exist" error for fresh cases) ----
      pre_delete = Tools::DeleteBalancing.call(
        params: { "mode" => "item", "debet_key" => debet_key, "credit_key" => credit_key },
        context: integration_context
      )

      had_existing = pre_delete[:status] == "deleted"
      if pre_delete.key?(:error)
        $stderr.puts "[integration] pre-delete: #{pre_delete[:error]} (ok if no prior balancing existed)"
      end

      # ---- STEP 2: INSERT ----
      insert_result = Tools::InsertBalancing.call(
        params: {
          "debet_key"  => debet_key,
          "credit_key" => credit_key,
          "amount"     => TESTCASE[:amount]
        },
        context: integration_context
      )

      expect(insert_result).not_to have_key(:error),
        "insert_balancing failed: #{insert_result[:error]}; body=#{insert_result[:sent_body].inspect}"
      expect(insert_result[:status]).to eq("created")
      expect(insert_result[:sent_body]).to include("balanceAmount" => TESTCASE[:amount])

      # ---- STEP 3: verify presence via get_modified_balancings ----
      mod = Tools::GetModifiedBalancings.call(
        params: { "modified_timestamp" => "2000-01-01 00:00:00.000" },
        context: integration_context
      )

      found = (mod[:balancings] || []).any? do |sync|
        next false unless sync.is_a?(Hash) && sync["modifiedBalancings"]
        sync["modifiedBalancings"].any? do |item|
          item.dig("debetDocument", "balancingKey", "journalKey")         == TESTCASE[:debet_journal]  &&
            item.dig("debetDocument", "balancingKey", "documentSequenceNr") == TESTCASE[:debet_document_seq] &&
            item.dig("debetDocument", "balancingKey", "lineSequenceNr")     == TESTCASE[:debet_line_seq] &&
            item.dig("creditDocument", "balancingKey", "journalKey")        == TESTCASE[:credit_journal] &&
            item.dig("creditDocument", "balancingKey", "documentSequenceNr") == TESTCASE[:credit_document_seq] &&
            item.dig("creditDocument", "balancingKey", "lineSequenceNr")     == TESTCASE[:credit_line_seq]
        end
      end

      expect(found).to be true

      # ---- STEP 4: restore original state ----
      # If a balancing existed before the test, we just re-inserted it -> done.
      # If NOT, we need to clean up the one we just created.
      if had_existing || ENV["KEEP_TEST_BALANCING"]
        $stderr.puts "[integration] leaving balancing in place"
      else
        cleanup = Tools::DeleteBalancing.call(
          params: { "mode" => "item", "debet_key" => debet_key, "credit_key" => credit_key },
          context: integration_context
        )
        expect(cleanup[:status]).to eq("deleted")
      end
    end
  end
end
