module Jekyll
  module Kentico
    module Mappers
      class FilenameMapperFactory
        # @return [FilenameMapperFactory]
        def self.for(mapper_name)
          mapper_name = mapper_name || Jekyll::Kentico::Mappers::FilenameMapperFactory.to_s
          Module.const_get(mapper_name)
        end

        def initialize(item)
          @item = item
        end

        def execute
          @item.system.codename
        end

      protected
        attr_reader :item
      end
    end
  end
end