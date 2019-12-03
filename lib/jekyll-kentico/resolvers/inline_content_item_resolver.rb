module Kentico
  module Kontent
    module Jekyll
      module Resolvers
        class InlineContentItemResolver
          def self.for(config)
            class_name = config.inline_content_item_resolver
            class_name && Module.const_get(class_name).new
          end
        end
      end
    end
  end
end
