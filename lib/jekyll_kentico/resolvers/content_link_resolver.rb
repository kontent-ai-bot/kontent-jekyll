require 'delivery-sdk-ruby'

module Jekyll
  module Kentico
    module Resolvers
      class ContentLinkResolver < KenticoCloud::Delivery::Resolvers::ContentLinkResolver
        # @return [ContentLinkResolver]
        def self.for(config)
          class_name = config.content_link_resolver
          class_name && Module.const_get(class_name).new
        end
      end
    end
  end
end