require 'delivery-sdk-ruby'

module Jekyll
  module Kentico
    module Resolvers
      class ContentLinkResolver < Delivery::Resolvers::ContentLinkResolver
        # @return [ContentLinkResolver]
        def self.for(resolver_name)
          resolver_name && Module.const_get(resolver_name)
        end

        def initialize(base_url)
          @base_url = base_url
        end

        def resolve_link(link)
        end
      end
    end
  end
end