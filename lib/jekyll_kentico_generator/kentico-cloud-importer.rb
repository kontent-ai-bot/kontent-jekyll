require 'delivery-sdk-ruby'
require 'date'

require_relative 'utils/normalize-object'
require_relative 'mappers/mappers'
require_relative 'constants/constants'

class KenticoCloudImporter
  def initialize(config)
    @config = config.kentico
  end

  def pages
    generate_pages_from_items items_by_type
  end

  def posts
    generate_posts_from_items items_by_type
  end

  def taxonomies
    taxonomies = retrieve_taxonomies
    codenames = @config.taxonomies
    filtered_taxonomies = taxonomies.select { |taxonomy| codenames.include? taxonomy.system.codename }

    result = {}
    filtered_taxonomies.each do |taxonomy|
      taxonomy_data = {
        system: taxonomy.system,
        terms: taxonomy.terms,
      }

      result[taxonomy.system.codename] = Utils::normalize_object taxonomy_data
    end
    result
  end

  def data
    generate_data_from_items items_by_type
  end
private
  def delivery_client
    project_id = value_for @config, KenticoConfigKeys::PROJECT_ID
    secure_key = value_for @config, KenticoConfigKeys::SECURE_KEY

    Delivery::DeliveryClient.new project_id: project_id, secure_key: secure_key
  end

  def retrieve_taxonomies
    delivery_client.taxonomies.execute { |response| return response.taxonomies }
  end

  def retrieve_items
    delivery_client.items.execute { |response| return response.items }
  end

  def items_by_type
    return @items_by_type if @items_by_type
    @items_by_type = retrieve_items.group_by { |item| item.system.type }
  end

  def generate_data_from_items(items_by_type)
    config = @config.data

    data_items = {}
    config.each_pair do |item_type, type_info|
      items = items_by_type.find { |type, item| type == item_type.to_s }
      next unless items

      name = type_info.name
      item_mapper_name = type_info.data
      linked_items_mapper_names = type_info.linked_items

      data_mapper_factory = Jekyll::Kentico::Mappers::DataMapperFactory.for item_mapper_name

      items = items[1]
      items.each do |original_item|
        item = OpenStruct.new ({
          system: original_item.system,
          elements: original_item.elements
        })

        get_links = ->(c) { original_item.get_links c }
        data = Utils::normalize_object(data_mapper_factory.new(item,linked_items_mapper_names,  get_links).execute)

        data_items[name] = data
      end
    end
    data_items
  end

  def generate_posts_from_items(items_by_type)
    config = @config.posts
    layout = config.layout

    item_type = config.content_type

    items = items_by_type.find { |type, item| type == item_type.to_s }
    return unless items

    item_mapper_name = config.data
    page_name_mapper_name = config.name
    linked_items_mapper_names = config.linked_items
    content_mapper_name = config.content
    date_mapper_name = config.date

    filename_mapper_factory = Jekyll::Kentico::Mappers::FilenameMapperFactory.for page_name_mapper_name
    data_mapper_factory = Jekyll::Kentico::Mappers::DataMapperFactory.for item_mapper_name
    content_mapper_factory = Jekyll::Kentico::Mappers::ContentMapperFactory.for content_mapper_name
    date_mapper_factory = Jekyll::Kentico::Mappers::DateMapperFactory.for date_mapper_name

    items = items[1]
    posts_data = []
    items.each do |original_item|
      item = OpenStruct.new ({
        system: original_item.system,
        elements: original_item.elements
      })

      mapped_name = filename_mapper_factory.new(item).execute
      date = Date.parse(date_mapper_factory.new(item).execute)
      filename = "#{mapped_name}.html"
      get_links = ->(c) { original_item.get_links c }
      data = Utils::normalize_object(data_mapper_factory.new(item,linked_items_mapper_names,  get_links).execute)
      data['layout'] = layout if layout
      data['date'] = date if date
      content = content_mapper_factory.new(item).execute

      post_data = OpenStruct.new(:content => content, :data => data, :filename => filename)
      posts_data << post_data
    end
    posts_data
  end

  def generate_pages_from_items(items_by_type)
    pages_config = @config.pages
    default_layout = pages_config.default_layout
    index_page_codename = pages_config.index

    pages_data_by_collection = {}
    pages_config.content_type.each_pair do |item_type, type_info|
      items = items_by_type.find { |type, item| type == item_type.to_s }
      next unless items

      item_mapper_name = type_info.data
      page_name_mapper_name = type_info.name
      linked_items_mapper_names = type_info.linked_items
      content_mapper_name = type_info.content

      collection = type_info.collection
      layouts = type_info.layouts
      type_layout = type_info.layout

      filename_mapper_factory = Jekyll::Kentico::Mappers::FilenameMapperFactory.for page_name_mapper_name
      data_mapper_factory = Jekyll::Kentico::Mappers::DataMapperFactory.for item_mapper_name
      content_mapper_factory = Jekyll::Kentico::Mappers::ContentMapperFactory.for content_mapper_name

      pages_data = []
      pages_data_by_collection[collection] = pages_data

      items = items[1]
      items.each do |original_item|
        codename = original_item.system.codename
        is_index_page = index_page_codename == codename

        page_layout = layouts && layouts[codename]
        layout = page_layout || type_layout || default_layout

        item = OpenStruct.new ({
          system: original_item.system,
          elements: original_item.elements
        })

        mapped_name = filename_mapper_factory.new(item).execute
        filename = "#{is_index_page ? 'index' : mapped_name}.html"

        get_links = ->(c) { original_item.get_links c }
        data = Utils::normalize_object(data_mapper_factory.new(item,linked_items_mapper_names,  get_links).execute)
        data['layout'] = layout if layout
        content = content_mapper_factory.new(item).execute

        page_data = OpenStruct.new(:content => content, :data => data, :collection => collection, :filename => filename)
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
