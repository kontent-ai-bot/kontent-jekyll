module Jekyll
  module Kentico
    module Resolvers
      class ContentItemContentResolver
        # @return [ContentItemContentResolver]
        def self.for(config)
          resolver_name = config.content_item_content_resolver ||
            Jekyll::Kentico::Resolvers::ContentItemContentResolver.to_s

          ResolverUtils.get_resolver resolver_name
        end

        def resolve_content(item)
          resolver = ItemElementResolver.new item
          resolver.resolve_content
        end
      end
    end
  end
end
