module Kentico
  module Kontent
    module Resolvers
      ##
      # This class instantiate the resolver based on the name from configuration.

      class InlineContentItemResolver
        def self.for(config)
          class_name = config.inline_content_item_resolver
          class_name && Module.const_get(class_name).new
        end
      end
    end
  end
end
