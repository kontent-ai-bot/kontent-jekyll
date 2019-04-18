module Jekyll
  module Kentico
    module Resolvers
      class ContentItemDataResolver
        # @return [ContentItemDataResolver]
        def self.for(config)
          class_name = config.content_item_data_resolver || ContentItemDataResolver.to_s
          Module.const_get(class_name).new
        end

        def resolve_item(item)
          OpenStruct.new(
            system: item.system,
            elements: item.elements,
          )
        end
      end
    end
  end
end
