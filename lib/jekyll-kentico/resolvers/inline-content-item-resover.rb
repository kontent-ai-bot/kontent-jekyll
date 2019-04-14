require 'delivery-sdk-ruby'

module Jekyll
  module Kentico
    module Resolvers
      class InlineContentItemResolver < KenticoCloud::Delivery::Resolvers::InlineContentItemResolver
        # @return [InlineContentItemResolver]
        def self.for(resolver_name)
          resolver_name && Module.const_get(resolver_name)
        end
      end
    end
  end
end