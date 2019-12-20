module Kentico
  module Kontent
    module Resolvers
      ##
      # This class instantiate the resolver based on the name from configuration.

      class ContentLinkResolver
        def self.for(config)
          class_name = config.content_link_resolver
          class_name && Module.const_get(class_name).new
        end
      end
    end
  end
end