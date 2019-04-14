require_relative '../models/kentico-page'

class SiteProcessor
  def initialize(site)
    @site = site
  end

  def process_pages_data(pages_data_by_collection)
    pages_data_by_collection.each do |collection_name, pages_data|
      @site.pages += pages_data.map(&method(:to_kentico_page))

      next unless collection_name && !collection_name.empty?

      collection = Jekyll::Collection.new @site, collection_name
      @site.collections[collection_name] = collection

      pages_data.each do |page_data|
        path = page_data.filename
        page = create_document path, @site, collection, page_data
        collection.docs << page
      end
    end
  end

  def process_posts_data(posts_data)
    posts = @site.collections['posts']

    posts_data.each do |post_data|
      path = File.join @site.source, '_posts', post_data.filename
      post = create_document path, @site, posts, post_data

      posts.docs << post
    end
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