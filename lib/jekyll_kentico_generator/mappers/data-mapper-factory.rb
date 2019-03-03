module Jekyll
  module Kentico
    module Mappers
      class DataMapperFactory
        # @return [DataMapperFactory]
        def self.for(mapper_name)
          mapper_name ||= Jekyll::Kentico::Mappers::DataMapperFactory.to_s
          Module.const_get(mapper_name)
        end

        def initialize(item, linked_items_mappers, get_links, get_string)
          @item = item
          @linked_items_mappers = linked_items_mappers
          @get_links = get_links
          @get_string = get_string
        end

        def execute
          OpenStruct.new(
            system: @item.system,
            elements: elements
          )
        end

      private
        def elements
          mapped_elements = OpenStruct.new
          @item.elements.each_pair do |codename, element|
            begin
              linked_items = @get_links.call codename.to_s
            rescue
              linked_items = []
            end
            mapper_name = @linked_items_mappers && @linked_items_mappers[codename.to_s]
            parsed_element = parse_element element, mapper_name, linked_items, @get_string, codename
            mapped_elements[codename] = parsed_element
          end
          mapped_elements
        end

        def parse_element(element, mapper_name, linked_items, get_string, codename)
          value = element.value

          case element.type
          when ItemElement::LINKED_ITEMS
            mapper_factory = Jekyll::Kentico::Mappers::LinkedItemsMapperFactory.for mapper_name
            mapper = mapper_factory.new linked_items
            mapper.execute
          when ItemElement::ASSET
            value.map { |asset| asset['url'] }
          when ItemElement::RICH_TEXT
            get_string.call codename.to_s
          else
            value
          end
        end
      end
    end
  end
end
