require 'delivery-sdk-ruby'

module Jekyll
  module Kentico
    module Resolvers
      class InlineContentItemResolver < KenticoCloud::Delivery::Resolvers::InlineContentItemResolver
        # @return [InlineContentItemResolver]
        def self.for(config)
          resolver_name = config.inline_content_item_resolver

          resolver_name && ResolverUtils.get_resolver(resolver_name)
        end
      end
    end
  end
end