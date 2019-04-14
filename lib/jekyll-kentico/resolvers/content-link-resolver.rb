require 'delivery-sdk-ruby'

module Jekyll
  module Kentico
    module Resolvers
      class ContentLinkResolver < KenticoCloud::Delivery::Resolvers::ContentLinkResolver
        # @return [ContentLinkResolver]
        def self.for(config)
          resolver_name = config.content_link_resolver

          resolver_name && ResolverUtils.get_resolver(resolver_name)
        end
      end
    end
  end
end