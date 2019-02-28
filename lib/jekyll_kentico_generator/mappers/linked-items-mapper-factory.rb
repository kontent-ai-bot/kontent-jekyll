module Jekyll
  module Kentico
    module Mappers
      class LinkedItemsMapperFactory
        # @return [LinkedItemsMapperFactory]
        def self.for(mapper_name)
          mapper_name = mapper_name || Jekyll::Kentico::Mappers::LinkedItemsMapperFactory.to_s
          Module.const_get(mapper_name)
        end

        def initialize(linked_items)
          @linked_items = linked_items
        end

        def execute
          @linked_items.map do |item|
            get_links = ->(c) { item.get_links c }
            data_mapper = DataMapperFactory.new item, nil, get_links
            data_mapper.execute
          end
        end

      protected
        attr_reader :linked_items
      end
    end
  end
end