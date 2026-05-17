require "spec_helper"

# ─── GetPaymentList ──────────────────────────────────────────────────────────
RSpec.describe Tools::GetPaymentList do
  describe ".call" do
    let(:payments) { [{ "amount" => 100.0, "reference" => "INV-001" }] }

    it "returns the payment list" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bank/paymentlist")
        .to_return(status: 200, body: payments.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:payments]).to eq(payments)
      expect(result[:total]).to eq(1)
    end

    it "returns empty list when no payments" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bank/paymentlist")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:payments]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end

# ─── GetUnbalancedInvoices ───────────────────────────────────────────────────
RSpec.describe Tools::GetUnbalancedInvoices do
  describe ".call" do
    let(:invoices) { [{ "amount" => 500.0, "documentSequenceNr" => 3 }] }

    it "returns unbalanced invoices" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bank/invoices")
        .to_return(status: 200, body: invoices.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:invoices]).to eq(invoices)
      expect(result[:total]).to eq(1)
    end

    it "returns empty list when no unbalanced invoices" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bank/invoices")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:invoices]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end

# ─── GetEnvelopes ────────────────────────────────────────────────────────────
RSpec.describe Tools::GetEnvelopes do
  describe ".call" do
    let(:envelopes) { [{ "enveloppeKeyId" => 1, "description" => "Batch Jan" }] }

    it "returns envelopes" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bank/enveloppes")
        .to_return(status: 200, body: envelopes.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:envelopes]).to eq(envelopes)
      expect(result[:total]).to eq(1)
    end

    it "returns empty list when no envelopes" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bank/enveloppes")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:envelopes]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when configuration is missing" do
      result = described_class.call(params: {}, context: { "configuration" => {} })

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end

# ─── GetEnvelopeContent ──────────────────────────────────────────────────────
RSpec.describe Tools::GetEnvelopeContent do
  describe ".call" do
    let(:envelope) { { "enveloppeKeyId" => 5, "payments" => [{ "amount" => 100.0 }] } }

    it "returns envelope content" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/bank/enveloppes/5")
        .to_return(status: 200, body: envelope.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "envelope_key_id" => 5 },
        context: octopus_context
      )

      expect(result[:envelope]).to eq(envelope)
    end

    it "returns error when envelope_key_id is missing" do
      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("envelope_key_id")
    end

    it "returns error when configuration is missing" do
      result = described_class.call(
        params: { "envelope_key_id" => 5 },
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end

# ─── GetRappels ──────────────────────────────────────────────────────────────
RSpec.describe Tools::GetRappels do
  describe ".call" do
    let(:rappels) { [{ "relationId" => 10, "rappelId" => 1, "amount" => 500.0 }] }

    it "returns rappels for an expiration date" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/rappels")
        .with(query: { "expirationDate" => "2024-06-01" })
        .to_return(status: 200, body: rappels.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "expiration_date" => "2024-06-01" },
        context: octopus_context
      )

      expect(result[:rappels]).to eq(rappels)
      expect(result[:total]).to eq(1)
    end

    it "returns empty list when no rappels" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/rappels")
        .with(query: { "expirationDate" => "2024-06-01" })
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "expiration_date" => "2024-06-01" },
        context: octopus_context
      )

      expect(result[:rappels]).to eq([])
      expect(result[:total]).to eq(0)
    end

    it "returns error when expiration_date is missing" do
      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("expiration_date")
    end

    it "returns error when configuration is missing" do
      result = described_class.call(
        params: { "expiration_date" => "2024-06-01" },
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end

# ─── ExportRappel ────────────────────────────────────────────────────────────
RSpec.describe Tools::ExportRappel do
  describe ".call" do
    let(:rappel_data) { { "pdfContent" => "base64data" } }

    it "exports a rappel" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/rappels/export")
        .with(query: { "relationId" => "10", "rappelId" => "1" })
        .to_return(status: 200, body: rappel_data.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "relation_id" => 10, "rappel_id" => 1 },
        context: octopus_context
      )

      expect(result[:rappel]).to eq(rappel_data)
    end

    it "returns error when required params are missing" do
      result = described_class.call(
        params: { "relation_id" => 10 },
        context: octopus_context
      )

      expect(result[:error]).to include("rappel_id")
    end

    it "returns error when configuration is missing" do
      result = described_class.call(
        params: { "relation_id" => 10, "rappel_id" => 1 },
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end

# ─── ExportInvoice ───────────────────────────────────────────────────────────
RSpec.describe Tools::ExportInvoice do
  describe ".call" do
    let(:invoice_data) { { "invoiceData" => { "amount" => 121.0 }, "pdfContent" => nil } }

    it "exports an invoice" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/invoices/export")
        .with(query: hash_including("bookyearId" => "1", "journalKey" => "V1", "documentSequenceNr" => "5"))
        .to_return(status: 200, body: invoice_data.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_key" => "V1", "document_sequence_nr" => 5 },
        context: octopus_context
      )

      expect(result[:invoice]).to eq(invoice_data)
    end

    it "returns error when required params are missing" do
      result = described_class.call(
        params: { "bookyear_id" => 1 },
        context: octopus_context
      )

      expect(result[:error]).to include("Missing required parameters")
    end

    it "returns error when configuration is missing" do
      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_key" => "V1", "document_sequence_nr" => 5 },
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end

# ─── ExportDeliveryNote ──────────────────────────────────────────────────────
RSpec.describe Tools::ExportDeliveryNote do
  describe ".call" do
    let(:delivery_note_data) { { "deliveryNoteData" => { "lines" => [] }, "pdfContent" => nil } }

    it "exports a delivery note" do
      stub_octopus_full_auth
      stub_request(:get, "#{OctopusClient::BASE_URL}/dossiers/42/deliverynotes/export")
        .with(query: hash_including("bookyearId" => "1", "journalKey" => "L1", "documentSequenceNr" => "3"))
        .to_return(status: 200, body: delivery_note_data.to_json, headers: { "Content-Type" => "application/json" })

      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_key" => "L1", "document_sequence_nr" => 3 },
        context: octopus_context
      )

      expect(result[:delivery_note]).to eq(delivery_note_data)
    end

    it "returns error when required params are missing" do
      result = described_class.call(
        params: { "bookyear_id" => 1 },
        context: octopus_context
      )

      expect(result[:error]).to include("Missing required parameters")
    end

    it "returns error when configuration is missing" do
      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_key" => "L1", "document_sequence_nr" => 3 },
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end

# ─── GetInvoiceDeliveryStates ────────────────────────────────────────────────
RSpec.describe Tools::GetInvoiceDeliveryStates do
  describe ".call" do
    it "returns delivery states successfully" do
      stub_octopus_full_auth
      stub_request(:post, /#{Regexp.escape(OctopusClient::BASE_URL)}\/dossiers\/42\/invoices\/send\/report\/deliverystate/)
        .to_return(
          status: 200,
          body: [{ "status" => "delivered" }].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(
        params: { "bookyear_id" => 1, "journal_key" => "V1" },
        context: octopus_context
      )

      expect(result[:delivery_states]).to be_an(Array)
      expect(result[:total]).to eq(1)
    end

    it "returns error when bookyear_id is missing" do
      result = described_class.call(params: {}, context: octopus_context)

      expect(result[:error]).to include("bookyear_id")
    end

    it "returns error when configuration is missing" do
      result = described_class.call(
        params: { "bookyear_id" => 1 },
        context: { "configuration" => {} }
      )

      expect(result[:error]).to include("Missing Octopus configuration")
    end
  end
end
