# Base module for Dok service tool dispatch.
#
# Each tool is a class in the Tools namespace with a .call(params:, context:) method.
# Tools return a Hash or Array that gets serialized to JSON.
#
# Example:
#
#   module Tools
#     class ListItems
#       def self.call(params:, context:)
#         { items: ["a", "b", "c"], total: 3 }
#       end
#     end
#   end
#
module Tools
end
