module Jekyll
  module Kentico
    module Mappers
      class DateMapperFactory
        # @return[DateMapperFactory]
        def self.for(mapper_name)
          mapper_name = mapper_name || Jekyll::Kentico::Mappers::DateMapperFactory.to_s
          Module.const_get(mapper_name)
        end

        def initialize(item)
          @item = item
        end

        def execute
        end

      protected
        attr_reader :item
      end
    end
  end
end