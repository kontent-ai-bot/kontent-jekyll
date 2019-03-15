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
          item = Mappers::DataMapperFactory.new(item).execute

          resolve_content_item item
        end
      end
    end
  end
end