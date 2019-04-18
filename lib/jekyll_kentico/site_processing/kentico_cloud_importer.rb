require 'delivery-sdk-ruby'
require 'date'

require 'jekyll_kentico/constants/kentico_config_keys'
require 'jekyll_kentico/constants/page_type'

require 'jekyll_kentico/resolvers/content_front_matter_resolver'
require 'jekyll_kentico/resolvers/content_item_content_resolver'
require 'jekyll_kentico/resolvers/content_item_data_resolver'
require 'jekyll_kentico/resolvers/content_item_filename_resolver'
require 'jekyll_kentico/resolvers/inline_content_item_resolver'

require 'jekyll_kentico/utils/normalize_object'

module Jekyll
  module Kentico
    module SiteProcessing
      class KenticoCloudImporter
        include Jekyll::Kentico::Constants
        include Jekyll::Kentico::Resolvers
        include Jekyll::Kentico::Utils

        def initialize(config)
          @config = config
          @items_by_type_by_language = {}
        end

        def pages(language)
          generate_pages(items_by_type(language))
        end

        def posts(language)
          generate_posts(items_by_type(language))
        end

        def data(language)
          generate_data(items_by_type(language))
        end

        def taxonomies
          taxonomies = retrieve_taxonomies
          return unless taxonomies

          codenames = @config.taxonomies
          filtered_taxonomies = taxonomies.select { |taxonomy| codenames.include? taxonomy.system.codename }

          result = {}
          filtered_taxonomies.each do |taxonomy|
            taxonomy_data = {
              system: taxonomy.system,
              terms: taxonomy.terms
            }

            result[taxonomy.system.codename] = normalize_object(taxonomy_data)
          end
          result
        end

        private

        def delivery_client
          project_id = value_for(@config, KenticoConfigKeys::PROJECT_ID)
          secure_key = value_for(@config, KenticoConfigKeys::SECURE_KEY)

          KenticoCloud::Delivery::DeliveryClient.new(
            project_id: project_id,
            secure_key: secure_key,
            content_link_url_resolver: content_link_url_resolver,
            inline_content_item_resolver: inline_content_item_resolver
          )
        end

        def content_item_filename_resolver
          @content_item_filename_resolver ||= ContentItemFilenameResolver.for(@config)
        end

        def inline_content_item_resolver
          @inline_content_item_resolver ||= InlineContentItemResolver.for(@config)
        end

        def content_link_url_resolver
          @content_link_url_resolver ||= ContentLinkResolver.for(@config)
        end

        def retrieve_taxonomies
          delivery_client
            .taxonomies
            .request_latest_content
            .execute { |response| return response.taxonomies }
        end

        def retrieve_items(language)
          client = delivery_client.items
          client = client.language(language) if language
          client.request_latest_content
            .depth(@config.max_linked_items_depth || 1)
            .execute { |response| return response.items }
        end

        def items_by_type(language)
          @items_by_type_by_language[language] ||=
            retrieve_items(language).group_by { |item| item.system.type }
        end

        def resolve_content_item_data(item)
          return @content_item_data_resolver.resolve_item(item) if @content_item_data_resolver

          @content_item_data_resolver = ContentItemDataResolver.for(@config)
          @content_item_data_resolver.resolve_item(item)
        end

        def generate_data(items_by_type)
          config = @config.data

          data_items = {}
          config && config.each_pair do |item_type, name|
            items = items_by_type[item_type.to_s]
            next unless items

            name ||= item_type.to_s
            data_items[name] = items.map { |item| normalize_object(resolve_content_item_data(item)) }
          end
          data_items
        end

        def generate_posts(items_by_type)
          config = @config.posts
          return [] unless config

          type = config&.type
          content_element_name = config&.content

          posts = items_by_type[type.to_s]
          return [] unless posts

          posts_data = []
          posts.each do |post_item|
            content = ContentItemContentResolver.for(@config, content_element_name).resolve_content(post_item)
            front_matter = ContentFrontMatterResolver.resolve(@config, post_item, PageType::POST)
            front_matter = normalize_object(front_matter)

            date = post_item.elements[config.date || 'date'].value
            date_string = DateTime.parse(date).strftime('%Y-%m-%d')

            mapped_name = content_item_filename_resolver.resolve_filename(post_item)
            filename = "#{date_string}-#{mapped_name}.html"

            post_data = OpenStruct.new(content: content, front_matter: front_matter, filename: filename)
            posts_data << post_data
          end

          posts_data
        end

        def generate_pages(items_by_type)
          pages_config = @config.pages
          return {} unless pages_config

          pages_data = []
          pages_config.each_pair do |type, page_config|
            pages = items_by_type[type.to_s]
            next unless pages

            collection = page_config&.collection
            content_element_name = page_config&.content

            pages.each do |page_item|
              content = ContentItemContentResolver.for(@config, content_element_name).resolve_content(page_item)
              front_matter = ContentFrontMatterResolver.resolve(@config, page_item, PageType::PAGE)
              front_matter = normalize_object(front_matter)

              mapped_name = content_item_filename_resolver.resolve_filename(page_item)
              filename = "#{mapped_name}.html"

              page_data = OpenStruct.new(content: content, collection: collection, front_matter: front_matter, filename: filename)
              pages_data << page_data
            end
          end

          pages_data
        end

        def value_for(config, key)
          potential_value = config[key]
          return ENV[potential_value.gsub('ENV_', '')] if !potential_value.nil? && potential_value.start_with?('ENV_')
          potential_value
        end
      end
    end
  end
end
