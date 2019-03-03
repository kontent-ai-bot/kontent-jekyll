require_relative 'kentico-cloud-importer'

module Jekyll
  class KenticoPage < Page
    def initialize(site, page_info)
      @site = site
      @base = site.source
      @dir = page_info.collection
      @name = page_info.filename

      self.process(@name)

      self.data = page_info.data
      self.content = page_info.content
    end
  end
end

def autoload_mappers!(config)
  plugins_dir = config.plugins_dir

  mapper_search_path = File.join @base, plugins_dir, 'kentico', 'mappers'
  mapper_files = Utils.safe_glob mapper_search_path, File.join('**', '*.rb')

  External.require_with_graceful_fail mapper_files
rescue StandardError
  Jekyll::logger.debug "Couldn't find custom mappers"
end

def autoload_resolvers!(config)
  plugins_dir = config.plugins_dir

  search_path = File.join @base, plugins_dir, 'kentico', 'resolvers'
  files = Utils.safe_glob search_path, File.join('**', '*.rb')

  External.require_with_graceful_fail files
rescue StandardError
  Jekyll::logger.debug "Couldn't find custom resolvers"
end

class Processor
  def initialize(site)
    @site = site
  end

  def process_pages_data(pages_data_by_collection)
    pages_data_by_collection.each do |collection_name, pages_data|
      @site.pages += pages_data.map(&method(:to_page))

      next unless collection_name && !collection_name.empty?

      collection = Jekyll::Collection.new @site, collection_name
      @site.collections[collection_name] = collection

      pages_data.each do |page_data|
        path = File.join page_data.filename
        page = Jekyll::Document.new path, site: @site, collection: collection
        page.content = page_data.content
        page.data.merge! page_data.data
        collection.docs << page
      end
    end
  end

  def process_posts_data(posts_data)
    posts = @site.collections['posts']

    posts_data.each do |post_data|
      path = File.join @site.source, '_posts', post_data.filename
      post = Jekyll::Document.new path, site: @site, collection: posts
      post.content = post_data.content
      post.data.merge! post_data.data
      posts.docs << post
    end
  end

  def process_taxonomies(taxonomies)
    @site.data['taxonomies'] = taxonomies
  end

  def process_data(data_items)
    @site.data.merge! data_items
  end
private
  def to_page(page_data)
    Jekyll::KenticoPage.new(@site, page_data)
  end
end

module Jekyll
  class ContentGenerator < Generator
    safe true

    def generate(site)
      config = JSON.parse(
        JSON.generate(site.config),
        object_class: OpenStruct
      )

      Jekyll::logger.info 'Starting import from Kentico Cloud'

      processor = Processor.new site

      autoload_mappers! config
      autoload_resolvers! config
      importer = KenticoCloudImporter.new(config)

      processor.process_pages_data importer.pages
      processor.process_posts_data importer.posts
      processor.process_taxonomies importer.taxonomies
      processor.process_data importer.data

      Jekyll::logger.info 'Import finished'
    end
  end
end