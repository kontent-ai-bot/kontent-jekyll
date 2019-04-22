module Jekyll
  module Kentico
    module SiteProcessing
      class CustomSiteProcessor
        def self.for(config)
          class_name = config.custom_site_processor
          class_name && Module.const_get(class_name).new
        end
      end
    end
  end
end
