module Jekyll
  module Kentico
    module Mappers
      class DataMapperFactory
        # @return [DataMapperFactory]
        def self.for(mapper_name)
          mapper_name = mapper_name || Jekyll::Kentico::Mappers::DataMapperFactory.to_s
          Module.const_get(mapper_name)
        end

        def initialize(item, linked_items_mappers, get_links)
          @item = item
          @linked_items_mappers = linked_items_mappers
          @get_links = get_links
        end

        def execute
          {
            system: @item.system,
            elements: elements
          }
        end

      protected
        attr_reader :item,
                    :linked_items_mappers,
                    :get_links

      private
        def elements
          mapped_elements = {}
          @item.elements.each_pair do |codename, element|
            begin
              linked_items = @get_links.call codename.to_s
            rescue
              linked_items = []
            end
            mapper_name = @linked_items_mappers && @linked_items_mappers[codename.to_s]
            parsed_element = parse_element element, mapper_name, linked_items
            mapped_elements[codename] = parsed_element
          end
          mapped_elements
        end

        def parse_element(element, mapper_name, linked_items)
          value = element.value

          case element.type
          when ItemElement::LINKED_ITEMS
            mapper_factory = Jekyll::Kentico::Mappers::LinkedItemsMapperFactory.for mapper_name
            mapper = mapper_factory.new linked_items
            mapper.execute
          when ItemElement::ASSET
            value.map { |asset| asset['url'] }
          else
            value
          end
        end
      end
    end
  end
end
