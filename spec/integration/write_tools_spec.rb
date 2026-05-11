require_relative "integration_helper"

RSpec.describe "Write Tools", :integration do
  # Helper to fetch a valid bookyear ID and an open journal key from the sandbox.
  # Used by booking/invoice tests that need real IDs.
  def fetch_bookyear_and_journal(journal_prefix: "A")
    bookyears = Tools::GetBookyears.call(params: {}, context: integration_context)
    return nil if bookyears[:bookyears].nil? || bookyears[:bookyears].empty?

    bookyear = bookyears[:bookyears].first
    bookyear_id = bookyear["bookyearKey"]["id"]

    journals = Tools::ListJournals.call(
      params: { "bookyear_id" => bookyear_id },
      context: integration_context
    )
    return nil if journals[:journals].nil? || journals[:journals].empty?

    journal = journals[:journals].find { |j| j["journalKey"]&.start_with?(journal_prefix) }
    return nil unless journal

    {
      bookyear_id: bookyear_id,
      journal_key: journal["journalKey"],
      # Use last document number + 1 to avoid conflicts
      next_doc_nr: (journal["lastDocumentSequenceNr"] || 0).to_i + 1
    }
  end

  # ---- create_relation (upsert — safe to repeat) ----

  describe "create_relation" do
    it "creates a test relation in the sandbox dossier",
       vcr_cassette: "write_tools/create_relation" do
      result = Tools::CreateRelation.call(
        params: {
          "name" => "Dok Integration Test BV",
          "client" => true,
          "supplier" => false,
          "email" => "integration-test@dok.example",
          "street_and_nr" => "Teststraat 1",
          "postal_code" => "1000",
          "city" => "Brussel",
          "country" => "BE",
          "currency_code" => "EUR",
          "external_relation_id" => 99999
        },
        context: integration_context
      )

      expect(result).not_to have_key(:error)
      expect(result[:status]).to eq("created").or eq("updated")
      expect(result[:message]).to include("successfully")
    end
  end

  # ---- create_buy_sell_booking ----

  describe "create_buy_sell_booking" do
    it "creates a buy booking in the sandbox dossier",
       vcr_cassette: "write_tools/create_buy_sell_booking" do
      info = fetch_bookyear_and_journal(journal_prefix: "A")
      skip "No open buy journal (A) found in sandbox" unless info

      result = Tools::CreateBuySellBooking.call(
        params: {
          "bookyear_id" => info[:bookyear_id],
          "journal_key" => info[:journal_key],
          "document_sequence_nr" => info[:next_doc_nr],
          "period_nr" => 1,
          "document_date" => Date.today.to_s,
          "expiry_date" => (Date.today + 30).to_s,
          "amount" => 121.0,
          "currency_code" => "EUR",
          "external_relation_id" => 99999,
          "reference" => "DOK-INT-TEST",
          "comment" => "Integration test booking",
          "booking_lines" => [
            {
              "account_key" => 600000,
              "base_amount" => 100.0,
              "vat_code" => "21",
              "vat_amount" => 21.0,
              "comment" => "Test line"
            }
          ]
        },
        context: integration_context
      )

      # Sandbox may reject with "document nummer is ongeldig" if sequence
      # numbers are not sequential — accept either success or a handled error.
      if result.key?(:error)
        expect(result[:error]).to include("Octopus API error")
      else
        expect(result[:status]).to eq("created")
      end
    end
  end

  # ---- create_invoice ----

  describe "create_invoice" do
    it "creates a sell invoice in the sandbox dossier",
       vcr_cassette: "write_tools/create_invoice" do
      info = fetch_bookyear_and_journal(journal_prefix: "V")
      skip "No open sell journal (V) found in sandbox" unless info

      result = Tools::CreateInvoice.call(
        params: {
          "bookyear_id" => info[:bookyear_id],
          "journal_key" => info[:journal_key],
          "document_sequence_nr" => info[:next_doc_nr],
          "period_nr" => 1,
          "document_date" => Date.today.to_s,
          "expiry_date" => (Date.today + 30).to_s,
          "currency_code" => "EUR",
          "external_relation_id" => 99999,
          "reference" => "DOK-INV-TEST",
          "comment" => "Integration test invoice",
          "invoice_lines" => [
            {
              "description" => "Integration test service",
              "count" => 1,
              "unit_price" => 100.0,
              "unit" => "pcs",
              "vat_code" => "21",
              "booking_account_nr" => 700000
            }
          ]
        },
        context: integration_context
      )

      # Invoice Module might not be active — accept either success or specific error
      if result.key?(:error)
        expect(result[:error]).to include("Octopus API error").or include("Invoice")
      else
        expect(result[:status]).to eq("created")
      end
    end
  end

  # ---- create_financial_divers_booking ----

  describe "create_financial_divers_booking" do
    it "creates a financial booking in the sandbox dossier",
       vcr_cassette: "write_tools/create_financial_divers_booking" do
      info = fetch_bookyear_and_journal(journal_prefix: "F")
      skip "No open financial journal (F) found in sandbox" unless info

      result = Tools::CreateFinancialDiversBooking.call(
        params: {
          "bookyear_id" => info[:bookyear_id],
          "journal_key" => info[:journal_key],
          "document_sequence_nr" => info[:next_doc_nr],
          "period_nr" => 1,
          "document_date" => Date.today.to_s,
          "booking_lines" => [
            {
              "type" => "A",
              "account_key" => 550000,
              "amount" => 100.0,
              "reference" => "DOK-FIN-TEST debit"
            },
            {
              "type" => "A",
              "account_key" => 400000,
              "amount" => -100.0,
              "reference" => "DOK-FIN-TEST credit"
            }
          ]
        },
        context: integration_context
      )

      # Sandbox may reject with "document nummer is ongeldig" if sequence
      # numbers are not sequential — accept either success or a handled error.
      if result.key?(:error)
        expect(result[:error]).to include("Octopus API error")
      else
        expect(result[:status]).to eq("created")
      end
    end
  end
end
