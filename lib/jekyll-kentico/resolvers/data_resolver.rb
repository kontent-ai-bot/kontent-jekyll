module Kentico
  module Kontent
    module Jekyll
      module Resolvers

        ##
        # This class resolve the data that will be injected into 'site.data' object.
        # If no user-defined resolver was provided or it returned nil
        # then content will be resolved in a default way.

        class DataResolver
          def initialize(global_config)
            @global_config = global_config
          end

          def execute(content_item)
            data = custom_resolver && custom_resolver.resolve(content_item)
            data || resolve_internal(content_item)
          end

          private

          ##
          # User-provided provided resolver is instantiated based on the name from configuration.

          def custom_resolver
            return @custom_resolver if @custom_resolver

            resolver_name = @global_config.data_resolver
            return unless resolver_name

            @custom_resolver = Module.const_get(resolver_name).new
          end

          ##
          # It resolves the content item and outputs only system and element fields as the original
          # item also contains methods, etc.

          def resolve_internal(item)
            OpenStruct.new(
              system: item.system,
              elements: item.elements,
            )
          end
        end
      end
    end
  end
end
