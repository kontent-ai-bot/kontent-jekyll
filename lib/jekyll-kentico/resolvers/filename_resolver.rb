module Kentico
  module Kontent
    module Jekyll
      module Resolvers

        ##
        # This class resolve the filename of the page.
        # If no user-defined resolver was provided or it returned nil
        # then content will be resolved in a default way.

        class FilenameResolver
          def initialize(global_config)
            @global_config = global_config
          end

          def execute(content_item)
            filename = custom_resolver && custom_resolver.resolve(content_item)
            filename || resolve_internal(content_item)
          end

          private

          ##
          # User-provided provided resolver is instantiated based on the name from configuration.

          def custom_resolver
            return @custom_resolver if @custom_resolver

            resolver_name = @global_config.filename_resolver
            return unless resolver_name

            @custom_resolver = Module.const_get(resolver_name).new
          end

          ##
          # Internal resolver will try to locate the url slug element and return its value.
          # If no slug was present then the item's codename will be used as the filename.

          def resolve_internal(content_item)
            url_slug = get_url_slug(content_item)
            url_slug&.value || content_item.system.codename
          end

          def get_url_slug(item)
            item.elements.each_pair { |_codename, element| return element if slug?(element) }
          end

          def slug?(element)
            element.type == Constants::ItemElementType::URL_SLUG
          end
        end
      end
    end
  end
end
