require "sinatra/base"
require "json"

require_relative "lib/service"
require "octopus_client"

# Auto-load all tool files (including concerns subdirectory)
Dir[File.join(__dir__, "lib", "tools", "concerns", "*.rb")].each { |f| require f }
Dir[File.join(__dir__, "lib", "tools", "*.rb")].each { |f| require f }

# Dok Service — HTTP server exposing Octopus accounting tools to AI agents.
#
# Endpoints:
#   GET  /health  → 200 OK (liveness probe)
#   POST /call    → tool dispatch (JSON in, JSON out)
#
class DokService < Sinatra::Base
  # --- Tool Registry ---
  # Map tool names (from your manifest) to handler classes.
  # Each class must implement: .call(params:, context:) → Hash/Array
  TOOLS = {
    # Read tools - Basic data
    "list_dossiers"                   => Tools::ListDossiers,
    "get_bookyears"                   => Tools::GetBookyears,
    "get_bookyear"                    => Tools::GetBookyear,
    "get_api_version"                 => Tools::GetApiVersion,
    "list_relations"                  => Tools::ListRelations,
    "list_accounts"                   => Tools::ListAccounts,
    "list_journals"                   => Tools::ListJournals,
    
    # Read tools - Reference data
    "get_cost_centres"                => Tools::GetCostCentres,
    "get_active_cost_centres"         => Tools::GetActiveCostCentres,
    "get_products"                    => Tools::GetProducts,
    "get_product_groups"              => Tools::GetProductGroups,
    "get_vat_codes"                   => Tools::GetVatCodes,
    "get_currencies"                  => Tools::GetCurrencies,
    "get_custom_fields"               => Tools::GetCustomFields,
    
    # Read tools - Bookings and documents
    "list_buy_sell_bookings"          => Tools::ListBuySellBookings,
    "list_financial_divers_bookings"  => Tools::ListFinancialDiversBookings,
    "list_invoices"                   => Tools::ListInvoices,
    "list_delivery_notes"             => Tools::ListDeliveryNotes,
    "get_journal_entry"               => Tools::GetJournalEntry,
    "get_financial_journal_balance"   => Tools::GetFinancialJournalBalance,
    
    # Read tools - Payments and banking
    "get_payment_list"                => Tools::GetPaymentList,
    "get_unbalanced_invoices"         => Tools::GetUnbalancedInvoices,
    "get_envelopes"                   => Tools::GetEnvelopes,
    "get_envelope_content"            => Tools::GetEnvelopeContent,
    
    # Read tools - Rappels and exports
    "get_rappels"                     => Tools::GetRappels,
    "export_rappel"                   => Tools::ExportRappel,
    "export_invoice"                  => Tools::ExportInvoice,
    "export_delivery_note"            => Tools::ExportDeliveryNote,
    "get_invoice_delivery_states"     => Tools::GetInvoiceDeliveryStates,
    
    # Read tools - Reports
    "report_history_accounts"         => Tools::ReportHistoryAccounts,
    "report_open_accounts"            => Tools::ReportOpenAccounts,
    "report_history_clients"          => Tools::ReportHistoryClients,
    "report_open_clients"             => Tools::ReportOpenClients,
    "report_history_suppliers"        => Tools::ReportHistorySuppliers,
    "report_open_suppliers"           => Tools::ReportOpenSuppliers,
    "report_history_cost_centres"     => Tools::ReportHistoryCostCentres,
    
    # Write tools - Create/update master data
    "create_relation"                 => Tools::CreateRelation,
    "create_or_update_account"        => Tools::CreateOrUpdateAccount,
    "create_or_update_cost_centre"    => Tools::CreateOrUpdateCostCentre,
    "create_or_update_product"        => Tools::CreateOrUpdateProduct,
    
    # Write tools - Bookings
    "create_buy_sell_booking"         => Tools::CreateBuySellBooking,
    "update_buy_sell_booking"         => Tools::UpdateBuySellBooking,
    "create_financial_divers_booking" => Tools::CreateFinancialDiversBooking,
    "update_financial_divers_booking" => Tools::UpdateFinancialDiversBooking,
    
    # Write tools - Invoices and delivery notes
    "create_invoice"                  => Tools::CreateInvoice,
    "update_invoice"                  => Tools::UpdateInvoice,
    "create_delivery_note"            => Tools::CreateDeliveryNote,
    "update_delivery_note"            => Tools::UpdateDeliveryNote,
    "generate_invoice"                => Tools::GenerateInvoice,
    "generate_delivery_note"          => Tools::GenerateDeliveryNote,
    "book_invoices"                   => Tools::BookInvoices,
    "send_invoices"                   => Tools::SendInvoices,
    
    # Write tools - Payments and banking
    "add_invoice_to_payment_list"     => Tools::AddInvoiceToPaymentList,
    "add_free_payment"                => Tools::AddFreePayment,
    "create_envelope"                 => Tools::CreateEnvelope,
    "update_envelope"                 => Tools::UpdateEnvelope,
    "add_payment_to_envelope"         => Tools::AddPaymentToEnvelope,
    "remove_payment_from_envelope"    => Tools::RemovePaymentFromEnvelope,
    "export_envelope"                 => Tools::ExportEnvelope,
    
    # Write tools - Balancing and bookyears
    "insert_balancing"                => Tools::InsertBalancing,
    "create_bookyear"                 => Tools::CreateBookyear,
    "update_bookyear"                 => Tools::UpdateBookyear,
    "book_bookyear"                   => Tools::BookBookyear
  }.freeze

  # --- Configuration ---
  set :port, ENV.fetch("PORT", 8080).to_i
  set :bind, "0.0.0.0"
  set :show_exceptions, false

  # Allow requests from any host — this service runs on an internal Docker
  # network (dok-services) and is only reachable via the Dok proxy, never
  # directly from the internet. Without this, Sinatra 4's rack-protection
  # blocks requests arriving with the Docker container hostname as Host header.
  set :host_authorization, { permitted_hosts: [] }

  # --- Endpoints ---

  get "/health" do
    "OK"
  end

  post "/call" do
    content_type :json

    body = request.body.read
    data = JSON.parse(body)

    tool_name = data["tool"]
    params    = data.fetch("params", {})
    context   = data.fetch("context", {})

    handler = TOOLS[tool_name]
    unless handler
      return { error: "Unknown tool: #{tool_name}" }.to_json
    end

    result = handler.call(params:, context:)
    result.to_json
  rescue JSON::ParserError => e
    status 400
    { error: "Invalid JSON: #{e.message}" }.to_json
  rescue => e
    $stderr.puts "[ERROR] #{tool_name}: #{e.class}: #{e.message}"
    $stderr.puts e.backtrace.first(5).join("\n")
    { error: "Internal error: #{e.message}" }.to_json
  end

  # Start the server when run directly: ruby app.rb
  run! if app_file == $0
end
