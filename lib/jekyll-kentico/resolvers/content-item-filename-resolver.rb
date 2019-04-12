module Jekyll
  module Kentico
    module Resolvers
      class ContentItemFilenameResolver
        # @return [ContentItemFilenameResolver]
        def self.for(resolver_name)
          resolver_name ||= Jekyll::Kentico::Resolvers::ContentItemFilenameResolver.to_s
          Module.const_get(resolver_name).new
        end

        def resolve_filename(item)
          item.system.codename
        end
      end
    end
  end
end
