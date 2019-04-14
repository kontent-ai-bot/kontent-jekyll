module Jekyll
  module Kentico
    module Resolvers
      class ContentItemContentResolver
        # @return [ContentItemContentResolver]
        def self.for(resolver_name)
          resolver_name ||= Jekyll::Kentico::Resolvers::ContentItemContentResolver.to_s
          Module.const_get(resolver_name).new
        end

        def resolve_content(item)
          resolver = ItemElementResolver.new item
          resolver.resolve_content
        end
      end
    end
  end
end
