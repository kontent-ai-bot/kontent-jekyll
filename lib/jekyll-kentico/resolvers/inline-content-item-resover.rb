require 'delivery-sdk-ruby'

module Jekyll
  module Kentico
    module Resolvers
      class InlineContentItemResolver < KenticoCloud::Delivery::Resolvers::InlineContentItemResolver
        # @return [InlineContentItemResolver]
        def self.for(resolver_name)
          resolver_name && Module.const_get(resolver_name)
        end

        def resolve_item(item)
          item = ContentItemResolver.resolve_item(item)

          resolve_content_item item
        end
      end
    end
  end
end