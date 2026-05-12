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
    # Read tools
    "list_dossiers"                   => Tools::ListDossiers,
    "get_bookyears"                   => Tools::GetBookyears,
    "list_relations"                  => Tools::ListRelations,
    "list_accounts"                   => Tools::ListAccounts,
    "list_journals"                   => Tools::ListJournals,
    "list_buy_sell_bookings"          => Tools::ListBuySellBookings,
    "list_invoices"                   => Tools::ListInvoices,
    # Write tools
    "create_relation"                 => Tools::CreateRelation,
    "create_buy_sell_booking"         => Tools::CreateBuySellBooking,
    "create_invoice"                  => Tools::CreateInvoice,
    "create_financial_divers_booking" => Tools::CreateFinancialDiversBooking
  }.freeze

  # --- Configuration ---
  set :port, ENV.fetch("PORT", 8080).to_i
  set :bind, "0.0.0.0"
  set :show_exceptions, false

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
