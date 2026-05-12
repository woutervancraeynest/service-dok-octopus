# Book a bookyear to the next bookyear in the configured Octopus dossier.
#
# Transfers the closing balances from one bookyear to the opening balances
# of the next bookyear.
#
module Tools
  class BookBookyear
    extend OctopusAuth

    def self.call(params:, context:)
      book_data = build_book_data(params)

      with_dossier_connection(context) do |client|
        result = client.book_bookyear(book_data)
        {
          status: "booked",
          message: "Bookyear booked successfully.",
          result: result[:body]
        }
      end
    end

    private

    def self.build_book_data(params)
      data = {}

      data["fromBookyearId"] = params["from_bookyear_id"].to_i if params["from_bookyear_id"]
      data["toBookyearId"] = params["to_bookyear_id"].to_i if params["to_bookyear_id"]
      data["bookingDate"] = params["booking_date"] if params["booking_date"]
      data["copyAllAccountDescriptions"] = params["copy_all_account_descriptions"] unless params["copy_all_account_descriptions"].nil?

      data
    end
  end
end