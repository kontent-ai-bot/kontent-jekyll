module Jekyll
  module Kentico
    module Mappers
      class DataMapperFactory
        @@max_level_of_nesting = 1

        def self.set_max_level_of_nesting(max_level_of_nesting)
          @@max_level_of_nesting = max_level_of_nesting
        end

        # @return [DataMapperFactory]
        def self.for(mapper_name)
          mapper_name ||= Jekyll::Kentico::Mappers::DataMapperFactory.to_s
          Module.const_get(mapper_name)
        end

        def initialize(item, level_of_nesting = 0)
          @item = item
          @level_of_nesting = level_of_nesting
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
            parsed_element =
              case element.type
              when ItemElement::LINKED_ITEMS
                return [] unless @level_of_nesting < @@max_level_of_nesting
                @item.get_links(codename.to_s).map { |item| DataMapperFactory.new(item, @level_of_nesting + 1).execute }
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
