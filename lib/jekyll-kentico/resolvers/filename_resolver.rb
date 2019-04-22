module Jekyll
  module Kentico
    module Resolvers
      class FilenameResolver
        def self.for(config)
          class_name = config.filename_resolver || FilenameResolver.to_s
          Module.const_get(class_name).new
        end

        def resolve(item)
          url_slug = get_url_slug(item)
          url_slug&.value || item.system.codename
        end

        private

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
