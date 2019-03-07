require_relative 'kentico-cloud-importer'
require_relative 'utils/site-processor'

module Jekyll
  class ContentGenerator < Generator
    safe true

    def generate(site)
      Jekyll::logger.info 'Starting import from Kentico Cloud'

      config = parse_config site
      load_custom_processors! config
      process_site site, config

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
      mapper_search_path = File.join config.source, config.plugins_dir, 'kentico'
      mapper_files = Utils.safe_glob mapper_search_path, File.join('**', '*.rb')

      External.require_with_graceful_fail mapper_files
    end

    def process_site(site, config)
      importer = KenticoCloudImporter.new(config)

      processor = SiteProcessor.new site
      processor.process_pages_data importer.pages
      processor.process_posts_data importer.posts
      processor.process_taxonomies importer.taxonomies
      processor.process_data importer.data
    end
  end
end