module Jekyll
  module Kentico
    module Resolvers
      class ContentItemFilenameResolver
        # @return [ContentItemFilenameResolver]
        def self.for(config)
          class_name = config.content_item_filename_resolver ||
            Jekyll::Kentico::Resolvers::ContentItemFilenameResolver.to_s

          Module.const_get(class_name).new
        end

        def resolve_filename(item)
          url_slug = get_url_slug(item)
          url_slug && url_slug.value || item.system.codename
        end

      private
        def get_url_slug(item)
          item.elements.each_pair { |codename, element| return element if element.type == Constants::ItemElement::URL_SLUG }
        end
      end
    end
  end
end
