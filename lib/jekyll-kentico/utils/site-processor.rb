require_relative '../models/kentico-page'

class SiteProcessor
  def initialize(site)
    @site = site
  end

  def process_pages_data(pages_data_by_collection)
    pages_data_by_collection.each do |collection_name, pages_data|
      reserved_collections = %w(posts data)
      should_add_to_collection = collection_name && !collection_name.empty? && !reserved_collections.include?(collection_name)

      if should_add_to_collection
        collection_config = @site.config['collections'][collection_name]

        if collection_config
          collection_config['output'] = true unless defined?(collection_config['output'])
        else
          @site.config['collections'][collection_name] = { 'output' => true } unless collection_config
        end

        collection = @site.collections[collection_name] || Jekyll::Collection.new(@site, collection_name)
        @site.collections[collection_name] = collection

        pages_data.each do |page_data|
          path = if collection_name
                   File.join @site.source, "_#{collection_name}", page_data.filename
                 else
                   File.join @site.source, page_data.filename
                 end

          page = create_document path, @site, collection, page_data

          page.instance_eval 'merge_defaults'
          page.instance_eval 'read_post_data'

          collection.docs << page
        end

        collection.docs.sort!
      else
        @site.pages += pages_data.map(&method(:to_kentico_page))
      end
    end

    @site.pages.sort_by!(&:name)
  end

  def process_posts_data(posts_data)
    posts =  @site.posts

    posts_data.each do |post_data|
      path = File.join @site.source, '_posts', post_data.filename
      post = create_document path, @site, posts, post_data

      post.instance_eval 'merge_defaults'
      post.instance_eval 'read_post_data'

      posts.docs << post
    end

    posts.docs.sort!
  end

  def process_taxonomies(taxonomies)
    @site.data['taxonomies'] = taxonomies if taxonomies
  end

  def process_data(data_items)
    @site.data.merge! data_items
  end
private
  def to_kentico_page(page_data)
    Jekyll::KenticoPage.new(@site, page_data)
  end

  def create_document(path, site, collection, source)
    doc = Jekyll::Document.new path, site: site, collection: collection
    doc.content = source.content
    doc.data.merge! source.data
    doc
  end
end