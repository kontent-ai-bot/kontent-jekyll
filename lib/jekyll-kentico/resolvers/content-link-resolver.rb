require 'delivery-sdk-ruby'

module Jekyll
  module Kentico
    module Resolvers
      class ContentLinkResolver < KenticoCloud::Delivery::Resolvers::ContentLinkResolver
        # @return [ContentLinkResolver]
        def self.for(resolver_name)
          resolver_name && Module.const_get(resolver_name).new
        end
      end
    end
  end
end