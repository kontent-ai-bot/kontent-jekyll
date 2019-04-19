module Jekyll
  module Kentico
    module Resolvers
      class DataResolver
        def self.for(config)
          class_name = config.data_resolver || DataResolver.to_s
          Module.const_get(class_name).new
        end

        def resolve(item)
          OpenStruct.new(
            system: item.system,
            elements: item.elements,
          )
        end
      end
    end
  end
end
