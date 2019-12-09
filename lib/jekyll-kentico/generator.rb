require 'jekyll-kentico/site_processing/custom_site_processor'
require 'jekyll-kentico/site_processing/kentico_kontent_importer'
require 'jekyll-kentico/site_processing/site_processor'

module Jekyll
  DEFAULT_LANGUAGE = nil

  class ContentGenerator < Generator
    include ::Kentico::Kontent::Jekyll::SiteProcessing

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

    def parse_config(site)
      JSON.parse(
        JSON.generate(site.config),
        object_class: OpenStruct
      )
    end

    def load_custom_processors!(config)
      mapper_search_path = File.join(config.source, config.plugins_dir, 'kentico')
      mapper_files = Utils.safe_glob(mapper_search_path, File.join('**', '*.rb'))

      External.require_with_graceful_fail(mapper_files)
    end

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

    def create_importer(kentico_config)
      importer_name = ENV['RACK_TEST_IMPORTER'] || KenticoKontentImporter.to_s
      Module.const_get(importer_name).new(kentico_config)
    end
  end
end