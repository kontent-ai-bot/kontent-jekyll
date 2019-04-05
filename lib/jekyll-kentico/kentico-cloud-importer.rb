require 'delivery-sdk-ruby'
require 'date'

require_relative 'utils/utils'
require_relative 'resolvers/resolvers'
require_relative 'constants/constants'

class KenticoCloudImporter
  def initialize(config)
    @config = config
  end

  def pages
    generate_pages_from_items items_by_type
  end

  def posts
    generate_posts_from_items items_by_type
  end

  def data
    generate_data_from_items items_by_type
  end

  def taxonomies
    taxonomies = retrieve_taxonomies
    codenames = kentico_config.taxonomies

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
  def kentico_config
    @config.kentico
  end

  def delivery_client
    project_id = value_for kentico_config, KenticoConfigKeys::PROJECT_ID
    secure_key = value_for kentico_config, KenticoConfigKeys::SECURE_KEY

    KenticoCloud::Delivery::DeliveryClient.new project_id: project_id,
                                 secure_key: secure_key,
                                 content_link_url_resolver: content_link_url_resolver,
                                 inline_content_item_resolver: inline_content_item_resolver
  end

  def inline_content_item_resolver
    @inline_content_item_resolver ||= Jekyll::Kentico::Resolvers::InlineContentItemResolver.for(kentico_config.inline_content_item_resolver).new
  end

  def content_link_url_resolver
    @content_link_url_resolver ||= Jekyll::Kentico::Resolvers::ContentLinkResolver.for(kentico_config.content_link_resolver).new(@config.baseurl)
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
      .depth(kentico_config.max_linked_items_depth)
      .execute { |response| return response.items }
  end

  def items_by_type
    return @items_by_type if @items_by_type

    @items_by_type = retrieve_items.group_by { |item| item.system.type }
  end

  def resolve_content_item(item)
    return @content_item_resolver.resolve_item(item) if @content_item_resolver

    item_mapper_name = kentico_config.content_item_resolver

    @content_item_resolver = Jekyll::Kentico::Resolvers::ContentItemResolver.register(item_mapper_name)
    @content_item_resolver.resolve_item(item)
  end

  def generate_data_from_items(items_by_type)
    config = kentico_config.data

    data_items = {}
    config && config.each_pair do |item_type, type_info|
      items = items_by_type.find { |type, item| type == item_type.to_s }
      next unless items

      name = type_info.name || item_type.to_s

      items = items[1]
      items.each do |item|
        data = Utils.normalize_object(resolve_content_item(item))

        data_items[name] = data
      end
    end
    data_items
  end

  def generate_posts_from_items(items_by_type)
    config = kentico_config.posts
    layout = config.layout

    return unless config

    item_type = config.content_type
    items = items_by_type.find { |type, item| type == item_type.to_s }
    return unless items

    items = items[1]
    posts_data = []
    items.each do |item|
      item_resolver = ItemElementResolver.new item

      mapped_name = item_resolver.resolve_filename(config.name)
      date = item_resolver.resolve_date(config.date, 'date')
      content = item_resolver.resolve_element(config.content, 'content')
      filename = "#{mapped_name}.html"

      data = Utils.normalize_object(resolve_content_item(item))
      data['layout'] = layout if layout
      data['date'] = date if date

      post_data = OpenStruct.new(content: content, data: data, filename: filename)
      posts_data << post_data
    end
    posts_data
  end

  def generate_pages_from_items(items_by_type)
    pages_config = kentico_config.pages

    return unless pages_config && pages_config.content_types

    default_layout = pages_config.default_layout
    index_page_codename = pages_config.index

    pages_data_by_collection = {}
    pages_config.content_types.each_pair do |item_type, type_info|
      items = items_by_type.find { |type, item| type == item_type.to_s }
      next unless items

      collection = type_info.collection
      layouts = type_info.layouts
      type_layout = type_info.layout

      pages_data = []
      pages_data_by_collection[collection] = pages_data

      items = items[1]
      items.each do |item|
        codename = item.system.codename
        is_index_page = index_page_codename == codename

        page_layout = layouts && layouts[codename]
        layout = page_layout || type_layout || default_layout

        item_resolver = ItemElementResolver.new item

        content = item_resolver.resolve_element type_info.content, 'content'
        mapped_name = item_resolver.resolve_filename type_info.name
        filename = "#{is_index_page ? 'index' : mapped_name}.html"

        data = Utils.normalize_object(resolve_content_item(item))
        data['layout'] = layout if layout

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
