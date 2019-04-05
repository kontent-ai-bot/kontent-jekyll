module Jekyll
  module Kentico
    module Resolvers
      class ContentItemResolver
        @@max_linked_items_depth = 1

        def self.set_max_linked_items_depth(max_linked_items_depth)
          @@max_linked_items_depth = max_linked_items_depth
        end

        # @return [ContentItemResolver]
        def self.for(mapper_name)
          mapper_name ||= Jekyll::Kentico::Resolvers::ContentItemResolver.to_s
          Module.const_get(mapper_name)
        end

        def initialize(linked_items_depth = 0)
          @linked_items_depth = linked_items_depth
        end

        def resolve_item(item)
          @item = item

          OpenStruct.new(
            system: item.system,
            elements: elements
          )
        end

      private
        def elements
          mapped_elements = OpenStruct.new
          @item.elements.each_pair do |codename, element|
            parsed_element =
              case element.type
              when ItemElement::LINKED_ITEMS
                return [] unless @linked_items_depth < @@max_linked_items_depth
                @item.get_links(codename.to_s).map { |item| ContentItemResolver.new(@linked_items_depth + 1).resolve_item(item) }
              when ItemElement::ASSET
                element.value.map { |asset| asset['url'] }
              when ItemElement::RICH_TEXT
                @item.get_string codename.to_s
              else
                element.value
              end

            mapped_elements[codename] = parsed_element
          end
          mapped_elements
        end
      end
    end
  end
end
