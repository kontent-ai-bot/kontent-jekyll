require 'date'

require 'kontent-jekyll/constants/page_type'

require 'kontent-jekyll/models/kentico_page'

require 'kontent-jekyll/resolvers/front_matter_resolver'
require 'kontent-jekyll/resolvers/content_resolver'
require 'kontent-jekyll/resolvers/data_resolver'
require 'kontent-jekyll/resolvers/filename_resolver'

require 'kontent-jekyll/utils/normalize_object'

module Kentico
  module Kontent
    module SiteProcessing
      ##
      # This class processes the the imported content and populate Jekyll structures.

      class SiteProcessor
        include Constants
        include Resolvers
        include Utils
        include Models

        ##
        # These collections have specific purposes in the original Jekyll generation will be omitted.

        RESERVED_COLLECTIONS = %w(posts data)

        def initialize(site, config)
          @site = site
          @config = config
        end

        ##
        # Populates standard Jekyll pages and collections

        def process_pages(items_by_type)
          pages_config = @config.pages
          return unless pages_config

          pages_config.each_pair do |type, page_config|
            pages = items_by_type[type.to_s]
            next unless pages

            collection_name = page_config&.collection

            pages_data = []
            pages.each do |page_item|
              content = content_resolver.execute(page_item, page_config)
              front_matter = front_matter_resolver.execute(page_item, PageType::PAGE)
              front_matter = normalize_object(front_matter)

              mapped_name = filename_resolver.execute(page_item)
              filename = "#{mapped_name}.html"

              page_data = OpenStruct.new(content: content, collection: collection_name, front_matter: front_matter, filename: filename)
              pages_data << page_data
            end

            are_pages_from_collection = collection_name && !collection_name.empty? && !RESERVED_COLLECTIONS.include?(collection_name)

            unless are_pages_from_collection
              @site.pages += pages_data.map { |page_data| KenticoPage.new(@site, page_data) }
              next
            end

            collection_config = @site.config['collections'][collection_name]
            if collection_config
              collection_config['output'] = true unless defined?(collection_config['output'])
            else
              @site.config['collections'][collection_name] = { 'output' => true }
            end

            collection = @site.collections[collection_name] ||= Jekyll::Collection.new(@site, collection_name)

            pages_data.each do |page_data|
              path = File.join(@site.source, "_#{collection_name}", page_data.filename)

              page = create_document(path, @site, collection, page_data)

              page.instance_eval 'merge_defaults'
              page.instance_eval 'read_post_data'

              collection.docs << page
            end

            collection.docs = collection.docs.reverse.uniq(&:path).reverse
            collection.docs.sort!
          end

          @site.pages = @site.pages.reverse.uniq(&:path).reverse
          @site.pages.sort_by!(&:name)
        end

        ##
        # Populates posts part of the Jekyll site

        def process_posts(items_by_type)
          posts_config = @config.posts
          return unless posts_config

          type = posts_config&.type

          posts = items_by_type[type.to_s]
          return unless posts

          posts.each do |post_item|
            content = content_resolver.execute(post_item, posts_config)
            front_matter = front_matter_resolver.execute(post_item, PageType::POST)
            front_matter = normalize_object(front_matter)

            date = post_item.elements[posts_config.date || 'date'].value
            date_string = DateTime.parse(date).strftime('%Y-%m-%d')

            mapped_name = filename_resolver.execute(post_item)
            filename = "#{date_string}-#{mapped_name}.html"

            post_data = OpenStruct.new(content: content, front_matter: front_matter, filename: filename)

            path = File.join(@site.source, '_posts', filename)
            post = create_document(path, @site, @site.posts, post_data)

            ##
            # We need to invoke these private methods as they correctly populate certain data automatically.

            post.instance_eval 'merge_defaults'
            post.instance_eval 'read_post_data'

            @site.posts.docs << post
          end

          @site.posts.docs = @site.posts.docs.reverse.uniq(&:path).reverse
          @site.posts.docs.sort!
        end

        ##
        # Populates data part of the Jekyll site.

        def process_data(items_by_type)
          config = @config.data

          data_items = {}
          config && config.each_pair do |item_type, name|
            items = items_by_type[item_type.to_s]
            next unless items

            name ||= item_type.to_s
            processed_items = items.map do |item|
              data = data_resolver.execute(item)
              normalize_object(data)
            end

            data_items[name] = (data_items[name] || []) + processed_items
          end

          @site.data.merge!({ 'items' => data_items })
        end

        ##
        # Populates data part of the Jekyll site with taxonomies.

        def process_taxonomies(taxonomies)
          codenames = @config.taxonomies
          return unless codenames && taxonomies

          filtered_taxonomies = taxonomies.select { |taxonomy| codenames.include? taxonomy.system.codename }

          processed_taxonomies = {}
          filtered_taxonomies.each do |taxonomy|
            taxonomy_data = normalize_object({
               system: taxonomy.system,
               terms: taxonomy.terms,
            })

            processed_taxonomies[taxonomy.system.codename] = taxonomy_data
          end

          @site.data['taxonomies'] = processed_taxonomies
        end

        private

        ##
        # Creates a Jekyll::Document. Used for collections.

        def create_document(path, site, collection, source)
          doc = Jekyll::Document.new(path, site: site, collection: collection)
          doc.content = source.content
          doc.data.merge!(source.front_matter)
          doc
        end

        def content_resolver
          @content_resolver ||= Resolvers::ContentResolver.new(@config)
        end

        def filename_resolver
          @filename_resolver ||= Resolvers::FilenameResolver.new(@config)
        end

        def front_matter_resolver
          @front_matter_resolver ||= Resolvers::FrontMatterResolver.new(@config)
        end

        def data_resolver
          @data_resolver ||= Resolvers::DataResolver.new(@config)
        end
      end
    end
  end
end