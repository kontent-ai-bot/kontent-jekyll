require 'delivery-sdk-ruby'
require 'date'

require_relative 'utils/utils'
require_relative 'resolvers/resolvers'
require_relative 'constants/constants'

class KenticoCloudImporter
  def initialize(config)
    @config = config
    @items_by_type_by_language = {}
  end

  def pages(language)
    generate_pages_from_items items_by_type(language)
  end

  def posts(language)
    generate_posts_from_items items_by_type(language)
  end

  def data(language)
    generate_data_from_items items_by_type(language)
  end

  def taxonomies
    taxonomies = retrieve_taxonomies
    codenames = @config.taxonomies

    return unless taxonomies

    filtered_taxonomies = taxonomies.select { |taxonomy| codenames.include? taxonomy.system.codename }

    result = {}
    filtered_taxonomies.each do |taxonomy|
      taxonomy_data = {
        system: taxonomy.system,
        terms: taxonomy.terms
      }

      result[taxonomy.system.codename] = Utils.normalize_object taxonomy_data
    end
    result
  end
private
  def delivery_client
    project_id = value_for @config, KenticoConfigKeys::PROJECT_ID
    secure_key = value_for @config, KenticoConfigKeys::SECURE_KEY

    KenticoCloud::Delivery::DeliveryClient.new project_id: project_id,
                                 secure_key: secure_key,
                                 content_link_url_resolver: content_link_url_resolver,
                                 inline_content_item_resolver: inline_content_item_resolver
  end

  def content_item_permalink_resolver
    @content_item_permalink_resolver ||= Jekyll::Kentico::Resolvers::ContentItemPermalinkResolver.for @config
  end

  def content_item_content_resolver
    @content_item_content_resolver ||= Jekyll::Kentico::Resolvers::ContentItemContentResolver.for @config
  end

  def content_item_filename_resolver
    @content_item_filename_resolver ||= Jekyll::Kentico::Resolvers::ContentItemFilenameResolver.for @config
  end

  def inline_content_item_resolver
    @inline_content_item_resolver ||= Jekyll::Kentico::Resolvers::InlineContentItemResolver.for @config
  end

  def content_link_url_resolver
    @content_link_url_resolver ||= Jekyll::Kentico::Resolvers::ContentLinkResolver.for @config
  end

  def retrieve_taxonomies
    delivery_client
      .taxonomies
      .request_latest_content
      .execute { |response| return response.taxonomies }
  end

  def retrieve_items
    delivery_client
      .items
      .request_latest_content
      .depth(@config.max_linked_items_depth || 1)
      .execute { |response| return response.items }
  end

  def retrieve_localized_items(language)
    delivery_client
      .items
      .language(language)
      .request_latest_content
      .depth(@config.max_linked_items_depth || 1)
      .execute { |response| return response.items }
  end

  def items_by_type(language)
    items_by_type = @items_by_type_by_language[language]
    return items_by_type if items_by_type

    items =
      if language
        retrieve_localized_items(language)
      else
        retrieve_items
      end

    items_by_type = items.group_by { |item| item.system.type }
    @items_by_type_by_language[language] = items_by_type
    items_by_type
  end

  def resolve_content_item_data(item)
    return @content_item_data_resolver.resolve_item(item) if @content_item_data_resolver

    @content_item_data_resolver = Jekyll::Kentico::Resolvers::ContentItemDataResolver.for @config
    @content_item_data_resolver.resolve_item(item)
  end

  def generate_data_from_items(items_by_type)
    config = @config.data

    data_items = {}
    config && config.each_pair do |item_type, name|
      items = items_by_type[item_type.to_s]
      next unless items

      name ||= item_type.to_s
      data_items[name] = items.map { |item| Utils.normalize_object(resolve_content_item_data(item)) }
    end
    data_items
  end

  def generate_posts_from_items(items_by_type)
    config = @config.posts

    return [] unless config

    type = config&.type
    layout = config&.layout
    date_element_name = config&.date
    title_element_name = config&.title
    categories_taxonomy_group = config&.categories
    tags_taxonomy_group = config&.tags

    posts = items_by_type[type.to_s]

    return [] unless posts

    posts_data = []
    posts.each do |post_item|
      content = content_item_content_resolver.resolve_content post_item
      permalink = content_item_permalink_resolver.resolve_permalink post_item

      item_resolver = ItemElementResolver.new post_item
      date = item_resolver.resolve_date date_element_name
      date_string = date && date.strftime('%Y-%m-%d')
      title = item_resolver.resolve_title title_element_name
      categories = item_resolver.resolve_taxonomy_group categories_taxonomy_group
      tags  = item_resolver.resolve_taxonomy_group tags_taxonomy_group

      mapped_name = content_item_filename_resolver.resolve_filename(post_item)
      filename = if date_string
                   "#{date_string}-#{mapped_name}.html"
                 else
                   "#{mapped_name}.html"
                 end

      data = { 'data' => Utils.normalize_object(resolve_content_item_data(post_item)) }
      data['title'] = title if title
      data['layout'] = layout if layout
      data['date'] =  Time.parse(date_string) if date_string
      data['categories'] = categories if categories
      data['tags'] = tags if tags
      data['permalink'] = permalink if permalink

      post_data = OpenStruct.new(content: content, data: data, filename: filename)
      posts_data << post_data
    end

    posts_data
  end

  def generate_pages_from_items(items_by_type)
    pages_config = @config.pages
    default_page_layout = @config.default_layout

    return {} unless pages_config

    pages_data_by_collection = {}
    pages_config.each_pair do |type, page_config|
      pages = items_by_type[type.to_s]
      next unless pages

      collection = page_config&.collection
      layout = page_config&.layout || default_page_layout
      title_element_name = page_config&.title

      unless pages_data_by_collection.key? collection
        pages_data_by_collection[collection] = []
      end
      pages_data = pages_data_by_collection[collection]

      pages.each do |page_item|
        content = content_item_content_resolver.resolve_content page_item
        permalink = content_item_permalink_resolver.resolve_permalink page_item

        mapped_name = content_item_filename_resolver.resolve_filename(page_item)
        filename = "#{mapped_name}.html"

        item_resolver = ItemElementResolver.new page_item
        title = item_resolver.resolve_title title_element_name

        data = { 'data' => Utils.normalize_object(resolve_content_item_data(page_item)) }
        data['title'] = title if title
        data['layout'] = layout if layout
        data['permalink'] = permalink if permalink

        page_data = OpenStruct.new(content: content, data: data, collection: collection, filename: filename)
        pages_data << page_data
      end
    end

    pages_data_by_collection
  end

  def value_for(config, key)
    potential_value = config[key]
    return ENV[potential_value.gsub('ENV_', '')] if !potential_value.nil? && potential_value.start_with?('ENV_')
    potential_value
  end
end
