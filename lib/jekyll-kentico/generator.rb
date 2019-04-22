require 'jekyll-kentico/site_processing/kentico_cloud_importer'
require 'jekyll-kentico/site_processing/site_processor'

module Jekyll
  DEFAULT_LANGUAGE = nil

  class ContentGenerator < Generator
    include Kentico::SiteProcessing

    safe true
    priority :highest

    def generate(site)
      Jekyll::logger.info 'Importing from Kentico Cloud...'

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
      importer = KenticoCloudImporter.new(kentico_config)

      processor = SiteProcessor.new(site)

      pages = []
      posts = []
      data = {}

      languages = kentico_config.languages || [DEFAULT_LANGUAGE]
      languages.each do |language|
        pages += importer.pages(language)
        posts += importer.posts(language)

        importer.data(language).each do |key, items|
          data[key] = (data[key] || []) + items
        end
      end

      processor.process_pages(pages)
      processor.process_posts(posts)
      processor.process_data(data)
      processor.process_taxonomies(importer.taxonomies)
    end
  end
end