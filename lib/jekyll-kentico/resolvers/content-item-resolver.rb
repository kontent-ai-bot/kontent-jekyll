module Jekyll
  module Kentico
    module Resolvers
      class ContentItemDataResolver
        @@resolver = nil

        # @return [ContentItemDataResolver]
        def self.register(resolver_name)
          return @@resolver if @@resolver

          resolver_name ||= Jekyll::Kentico::Resolvers::ContentItemDataResolver.to_s
          @@resolver = Module.const_get(resolver_name).new
        end

        def self.resolve_item(item)
          @@resolver.resolve_item item if @@resolver
        end

        def resolve_item(item)
          OpenStruct.new(
            system: item.system,
            elements: process_elements(item)
          )
        end

        def resolve_element(params)
          params.element
        end

      private
        def process_elements(item)
          get_links = ->(element) { item.get_links element.codename }
          get_string = ->(element) { item.get_string element.codename }

          mapped_elements = OpenStruct.new
          item.elements.each_pair do |codename, element|
            element[:codename] = codename.to_s
            params = OpenStruct.new element: element,
                                    get_links: get_links,
                                    get_string: get_string
            resolved_element = resolve_element params
            mapped_elements[codename] = resolved_element
          end
          mapped_elements
        end
      end
    end
  end
end
