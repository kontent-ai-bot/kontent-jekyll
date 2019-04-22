module Jekyll
  module Kentico
    module Resolvers
      class ContentResolver
        def self.for(config, content_element_name)
          registered_resolver = config.content_resolver
          default_resolver = ContentResolver.to_s

          if registered_resolver
            Module.const_get(registered_resolver).new
          else
            Module.const_get(default_resolver).new(content_element_name)
          end
        end

        def initialize(content_element_name)
          @content_element_name = content_element_name
        end

        def resolve(item)
          item.get_string(@content_element_name || 'content')
        end
      end
    end
  end
end
