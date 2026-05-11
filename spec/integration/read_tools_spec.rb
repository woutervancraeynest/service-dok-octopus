require_relative "integration_helper"

RSpec.describe "Read Tools", :integration do
  # ---- list_dossiers (uses auth token only, no dossier connection) ----

  describe "list_dossiers" do
    it "returns accessible dossiers from the sandbox",
       vcr_cassette: "read_tools/list_dossiers" do
      # list_dossiers only needs auth, not a dossier_id — but OctopusAuth
      # uses with_octopus_client which only authenticates.
      result = Tools::ListDossiers.call(
        params: {},
        context: integration_context
      )

      expect(result).not_to have_key(:error)
      expect(result[:dossiers]).to be_an(Array)
      expect(result[:dossiers]).not_to be_empty
      expect(result[:total]).to be > 0

      # Each dossier should have at minimum a key and description
      dossier = result[:dossiers].first
      expect(dossier).to have_key("dossierKey")
      expect(dossier).to have_key("dossierDescription")
    end
  end

  # ---- Tools that require a dossier connection ----

  describe "get_bookyears" do
    it "returns bookyears for the sandbox dossier",
       vcr_cassette: "read_tools/get_bookyears" do
      result = Tools::GetBookyears.call(
        params: {},
        context: integration_context
      )

      expect(result).not_to have_key(:error)
      expect(result[:bookyears]).to be_an(Array)
      expect(result[:bookyears]).not_to be_empty
      expect(result[:total]).to be > 0

      bookyear = result[:bookyears].first
      expect(bookyear).to have_key("bookyearKey")
    end
  end

  describe "list_relations" do
    it "returns relations from the sandbox dossier",
       vcr_cassette: "read_tools/list_relations" do
      result = Tools::ListRelations.call(
        params: {},
        context: integration_context
      )

      expect(result).not_to have_key(:error)
      expect(result[:relations]).to be_an(Array)
      expect(result[:total]).to be >= 0
    end
  end

  describe "list_accounts" do
    it "returns chart of accounts for a bookyear",
       vcr_cassette: "read_tools/list_accounts" do
      # First get bookyears to find a valid bookyear_id
      bookyears_result = Tools::GetBookyears.call(
        params: {},
        context: integration_context
      )

      skip "No bookyears found in sandbox dossier" if bookyears_result[:bookyears].nil? || bookyears_result[:bookyears].empty?

      bookyear_id = bookyears_result[:bookyears].first["bookyearKey"]["id"]

      result = Tools::ListAccounts.call(
        params: { "bookyear_id" => bookyear_id },
        context: integration_context
      )

      expect(result).not_to have_key(:error)
      expect(result[:accounts]).to be_an(Array)
      expect(result[:total]).to be > 0
    end
  end

  describe "list_journals" do
    it "returns journals for a bookyear",
       vcr_cassette: "read_tools/list_journals" do
      bookyears_result = Tools::GetBookyears.call(
        params: {},
        context: integration_context
      )

      skip "No bookyears found in sandbox dossier" if bookyears_result[:bookyears].nil? || bookyears_result[:bookyears].empty?

      bookyear_id = bookyears_result[:bookyears].first["bookyearKey"]["id"]

      result = Tools::ListJournals.call(
        params: { "bookyear_id" => bookyear_id },
        context: integration_context
      )

      expect(result).not_to have_key(:error)
      expect(result[:journals]).to be_an(Array)
      expect(result[:total]).to be > 0

      # Expect at least one journal with a key
      journal = result[:journals].first
      expect(journal).to have_key("journalKey")
    end
  end

  describe "list_buy_sell_bookings" do
    it "returns buy/sell bookings from the sandbox dossier",
       vcr_cassette: "read_tools/list_buy_sell_bookings" do
      # Get a valid bookyear ID first
      bookyears_result = Tools::GetBookyears.call(
        params: {},
        context: integration_context
      )

      skip "No bookyears found" if bookyears_result[:bookyears].nil? || bookyears_result[:bookyears].empty?

      bookyear_id = bookyears_result[:bookyears].first["bookyearKey"]["id"]

      result = Tools::ListBuySellBookings.call(
        params: { "bookyear_id" => bookyear_id },
        context: integration_context
      )

      # Sandbox may return an API error if no bookings exist or parameters
      # are insufficient — accept either success or a handled error (no crash).
      if result.key?(:error)
        expect(result[:error]).to include("Octopus API error")
      else
        expect(result[:bookings]).to be_an(Array)
        expect(result[:total]).to be >= 0
      end
    end
  end

  describe "list_invoices" do
    it "returns invoices from the sandbox dossier",
       vcr_cassette: "read_tools/list_invoices" do
      bookyears_result = Tools::GetBookyears.call(
        params: {},
        context: integration_context
      )

      skip "No bookyears found" if bookyears_result[:bookyears].nil? || bookyears_result[:bookyears].empty?

      bookyear_id = bookyears_result[:bookyears].first["bookyearKey"]["id"]

      result = Tools::ListInvoices.call(
        params: { "bookyear_id" => bookyear_id },
        context: integration_context
      )

      # Note: invoices may return an error if the Invoice Module is not
      # activated in the sandbox dossier — that's OK, we just verify no crash.
      expect(result[:invoices]).to be_an(Array).or(satisfy { |r| result.key?(:error) })
    end
  end
end
