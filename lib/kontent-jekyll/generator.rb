require 'kontent-jekyll/site_processing/custom_site_processor'
require 'kontent-jekyll/site_processing/kentico_kontent_importer'
require 'kontent-jekyll/site_processing/site_processor'

module Kentico
  module Kontent
    ##
    # This class generates content stored in Kentico Kontent CMS and populute
    # particular Jekyll structures so the website is correctly outputted
    # during the build process.

    class ContentGenerator < Jekyll::Generator
      include SiteProcessing

      DEFAULT_LANGUAGE = nil

      safe true
      priority :highest

      def generate(site)
        Jekyll::logger.info 'Importing from Kentico Kontent...'

        config = parse_config(site)

        load_custom_processors!(config)
        process_site(site, config)

        Jekyll::logger.info 'Import finished'
      end

      private

      ##
      # Parses Jekyll configuration into OpenStruct structure.

      def parse_config(site)
        JSON.parse(
          JSON.generate(site.config),
          object_class: OpenStruct
        )
      end

      ##
      # Load custom resolvers from the _plugins/kentico directory.

      def load_custom_processors!(config)
        mapper_search_path = File.join(config.source, config.plugins_dir, 'kentico')
        mapper_files = Jekyll::Utils.safe_glob(mapper_search_path, File.join('**', '*.rb'))

        Jekyll::External.require_with_graceful_fail(mapper_files)
      end

      ##
      # Processed the site.
      # It imports KC content for every language from the config file.
      # Then it pass the content to the site processor to populate Jekyll structures.

      def process_site(site, config)
        kentico_config = config.kentico
        importer = create_importer(kentico_config)

        processor = SiteProcessor.new(site, kentico_config)

        all_items_by_type = {}

        languages = kentico_config.languages || [DEFAULT_LANGUAGE]
        languages.each do |language|
          items_by_type = importer.items_by_type(language)

          all_items_by_type.merge!(items_by_type) do |key, currentItems, newItems|
            currentItems || newItems
          end
        end

        taxonomies = importer.taxonomies

        processor.process_pages(all_items_by_type)
        processor.process_posts(all_items_by_type)
        processor.process_data(all_items_by_type)
        processor.process_taxonomies(taxonomies)

        unique_items = all_items_by_type
          .values
          .flatten(1)
          .uniq{ |i| "#{i.system.language};#{i.system.id}" }

        kentico_data = OpenStruct.new(
          items: unique_items,
          taxonomy_groups: taxonomies,
        )

        custom_site_processor = CustomSiteProcessor.for(kentico_config)
        custom_site_processor&.generate(site, kentico_data)
      end


      ##
      # Creates a desired content importer. RACK_TEST_IMPORTER class name and implementation
      # is specified in RSpec tests.

      def create_importer(kentico_config)
        importer_name = ENV['RACK_TEST_IMPORTER'] || KenticoKontentImporter.to_s
        Module.const_get(importer_name).new(kentico_config)
      end
    end
  end
end
