module Jekyll
  module Kentico
    module Resolvers
      class ContentLinkResolver
        def self.for(config)
          class_name = config.content_link_resolver
          class_name && Module.const_get(class_name).new
        end
      end
    end
  end
end