# Add a free payment to the payment list in the configured Octopus dossier.
#
# Adds a standalone payment entry that is not linked to a specific invoice.
#
module Tools
  class AddFreePayment
    extend OctopusAuth

    def self.call(params:, context:)
      payment_data = build_payment_data(params)

      with_dossier_connection(context) do |client|
        result = client.add_free_payment(payment_data)
        {
          status: "added",
          message: "Free payment added to payment list successfully.",
          result: result
        }
      end
    end

    private

    def self.build_payment_data(params)
      data = {}

      data["amount"] = params["amount"].to_f if params["amount"]
      data["reference"] = params["reference"] if params["reference"]
      data["iban"] = params["iban"] if params["iban"]
      data["bic"] = params["bic"] if params["bic"]
      data["beneficiaryName"] = params["beneficiary_name"] if params["beneficiary_name"]
      data["paymentDate"] = params["payment_date"] if params["payment_date"]
      data["description"] = params["description"] if params["description"]

      # Relation identification
      if params["relation_id"]
        data["relationKey"] = { "id" => params["relation_id"].to_i }
      elsif params["external_relation_id"]
        data["externalRelationId"] = params["external_relation_id"].to_i
      end

      data
    end
  end
end