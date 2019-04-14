module Jekyll
  module Kentico
    module Resolvers
      class ContentItemPermalinkResolver
        # @return [ContentItemContentResolver]
        def self.for(config)
          resolver_name = config.content_item_permalink_resolver ||
            Jekyll::Kentico::Resolvers::ContentItemPermalinkResolver.to_s

          ResolverUtils.get_resolver resolver_name
        end

        def resolve_permalink(item, collection)
        end
      end
    end
  end
end
