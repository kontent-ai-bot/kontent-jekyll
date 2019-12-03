module Kentico
  module Kontent
    module Jekyll
      module SiteProcessing
        RESERVED_COLLECTIONS = %w(posts data)

        class SiteProcessor
          def initialize(site)
            @site = site
          end

          def process_pages(pages_data)
            pages_data_by_collection = pages_data.group_by(&:collection)
            pages_data_by_collection.each do |collection_name, pages_data|
              should_add_to_collection = collection_name && !collection_name.empty? && !RESERVED_COLLECTIONS.include?(collection_name)

              unless should_add_to_collection
                @site.pages += pages_data.map { |page_data| create_kentico_page(@site, page_data) }
                next
              end

              collection_config = @site.config['collections'][collection_name]

              if collection_config
                collection_config['output'] = true unless defined?(collection_config['output'])
              else
                @site.config['collections'][collection_name] = { 'output' => true }
              end

              collection = @site.collections[collection_name] ||= ::Jekyll::Collection.new(@site, collection_name)

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

          def process_posts(posts_data)
            posts =  @site.posts

            posts_data.each do |post_data|
              path = File.join(@site.source, '_posts', post_data.filename)
              post = create_document(path, @site, posts, post_data)

              post.instance_eval 'merge_defaults'
              post.instance_eval 'read_post_data'

              posts.docs << post
            end

            posts.docs = posts.docs.reverse.uniq(&:path).reverse
            posts.docs.sort!
          end

          def process_taxonomies(taxonomies)
            @site.data['taxonomies'] = taxonomies if taxonomies
          end

          def process_data(data_items)
            @site.data.merge!({ 'items' => data_items })
          end

          private

          def create_kentico_page(site, page_info)
            page = ::Jekyll::Page.allocate

            # A hack to create a Jekyll::Page with custom constructor without overriding the class
            #   because rekyll-redirect-from can work only with Jekyll::Page instances.
            page.define_singleton_method(:initialize) do
              @site = site
              @base = site.source
              @dir = ''
              @name = page_info.filename
              @path = if site.in_theme_dir(@base) == @base
                        site.in_theme_dir(@base, @dir, @name)
                      else
                        site.in_source_dir(@base, @dir, @name)
                      end

              self.process(@name)

              self.data = page_info.front_matter
              self.content = page_info.content

              data.default_proc = proc do |_, key|
                site.frontmatter_defaults.find(File.join(@dir, @name), type, key)
              end

              ::Jekyll::Hooks.trigger :pages, :post_init, self

              self
            end

            page.initialize
          end

          def create_document(path, site, collection, source)
            doc = ::Jekyll::Document.new(path, site: site, collection: collection)
            doc.content = source.content
            doc.data.merge!(source.front_matter)
            doc
          end
        end
      end
    end
  end
end
