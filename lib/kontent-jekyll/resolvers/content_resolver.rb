module Kentico
  module Kontent
    module Resolvers
      ##
      # This class resolve the content of the content item to be injected
      # under the front matter part of the page.
      # If no user-defined resolver was provided or it returned nil
      # then content will be resolved in a default way.

      class ContentResolver
        def initialize(global_config)
          @global_config = global_config
        end

        def execute(content_item, config)
          content = custom_resolver && custom_resolver.resolve(content_item)
          content || resolve_internal(content_item, config)
        end

        private

        ##
        # User-provided provided resolver is instantiated based on the name from configuration.

        def custom_resolver
          return @custom_resolver if @custom_resolver

          resolver_name = @global_config.content_resolver
          return unless resolver_name

          @custom_resolver = Module.const_get(resolver_name).new
        end

        ##
        # Resolves content in a default way, it looks up element with a codename 'content'
        # or codename specified in the config and takes its string value. This also resolves
        # content components and linked items.

        def resolve_internal(content_item, config)
          element_name = config.content || 'content'
          element = content_item.elements[element_name]
          element && content_item.get_string(element_name)
        end
      end
    end
  end
end
