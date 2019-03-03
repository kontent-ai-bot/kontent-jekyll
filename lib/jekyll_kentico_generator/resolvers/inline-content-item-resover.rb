require 'delivery-sdk-ruby'

module Jekyll
  module Kentico
    module Resolvers
      class InlineContentItemResolver < Delivery::Resolvers::InlineContentItemResolver
        # @return [InlineContentItemResolver]
        def self.for(resolver_name)
          resolver_name && Module.const_get(resolver_name)
        end

        def resolve_item(item)
          data_mapper = Mappers::DataMapperFactory.for nil
          get_links = ->(c) { item.get_links c }
          get_string = ->(c) { item.get_string c }
          item = data_mapper.new(item, nil, get_links, get_string).execute

          resolve_content_item item
        end
      end
    end
  end
end