module Jekyll
  module Kentico
    module Resolvers
      class ContentItemFilenameResolver
        # @return [ContentItemFilenameResolver]
        def self.for(config)
          resolver_name = config.content_item_filename_resolver ||
            Jekyll::Kentico::Resolvers::ContentItemFilenameResolver.to_s

          ResolverUtils.get_resolver resolver_name
        end

        def resolve_filename(item)
          item.system.codename
        end
      end
    end
  end
end
