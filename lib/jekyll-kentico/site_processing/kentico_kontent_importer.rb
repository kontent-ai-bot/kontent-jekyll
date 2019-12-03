require 'kontent-delivery-sdk-ruby'
require 'date'

require 'jekyll-kentico/constants/kentico_config_keys'
require 'jekyll-kentico/constants/page_type'

require 'jekyll-kentico/resolvers/front_matter_resolver'
require 'jekyll-kentico/resolvers/content_resolver'
require 'jekyll-kentico/resolvers/data_resolver'
require 'jekyll-kentico/resolvers/filename_resolver'
require 'jekyll-kentico/resolvers/inline_content_item_resolver'

require 'jekyll-kentico/utils/normalize_object'

module Kentico
  module Kontent
    module Jekyll
      module SiteProcessing
        class KenticoKontentImporter
          include ::Kentico::Kontent::Jekyll::Constants
          include ::Kentico::Kontent::Jekyll::Resolvers
          include ::Kentico::Kontent::Jekyll::Utils

          def initialize(config)
            @config = config
            @items_by_type_by_language_cache = {}
            @items = []
            @taxonomy_groups = []
          end

          def kentico_data
            OpenStruct.new(
              items: @items.uniq{ |i| "#{i.system.language};#{i.system.id}" },
              taxonomy_groups: @taxonomy_groups
            )
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
            return @taxonomies_cache if @taxonomies_cache

            codenames = @config.taxonomies
            return {} unless codenames

            taxonomies = retrieve_taxonomies
            return {} unless taxonomies

            filtered_taxonomies = taxonomies.select { |taxonomy| codenames.include? taxonomy.system.codename }

            @taxonomies_cache = {}
            filtered_taxonomies.each do |taxonomy|
              @taxonomy_groups << taxonomy
              taxonomy_data = normalize_object({
                system: taxonomy.system,
                terms: taxonomy.terms
              })

              @taxonomies_cache[taxonomy.system.codename] = taxonomy_data
            end
            @taxonomies_cache
          end

          private

          def delivery_client
            project_id = value_for(@config, KenticoConfigKeys::PROJECT_ID)
            secure_key = value_for(@config, KenticoConfigKeys::SECURE_KEY)

            ::Kentico::Kontent::Delivery::DeliveryClient.new(
              project_id: project_id,
              secure_key: secure_key,
              content_link_url_resolver: content_link_url_resolver,
              inline_content_item_resolver: inline_content_item_resolver
            )
          end

          def content_resolver
            @content_resolver ||= ContentResolver.new(@config)
          end

          def filename_resolver
            @filename_resolver ||= FilenameResolver.new(@config)
          end

          def front_matter_resolver
            @front_matter_resolver ||= FrontMatterResolver.new(@config)
          end

          def data_resolver
            @data_resolver ||= DataResolver.new(@config)
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
            @items_by_type_by_language_cache[language] ||=
              retrieve_items(language)
                .tap { |items| @items += items }
                .group_by { |item| item.system.type }
          end

          def generate_data(items_by_type)
            config = @config.data

            data_items = {}
            config && config.each_pair do |item_type, name|
              items = items_by_type[item_type.to_s]
              next unless items

              name ||= item_type.to_s
              data_items[name] = items.map do |item|
                data = data_resolver.execute(item)
                normalize_object(data)
              end
            end
            data_items
          end

          def generate_posts(items_by_type)
            posts_config = @config.posts
            return [] unless posts_config

            type = posts_config&.type

            posts = items_by_type[type.to_s]
            return [] unless posts

            posts_data = []
            posts.each do |post_item|
              content = content_resolver.execute(post_item, posts_config)
              front_matter = front_matter_resolver.execute(post_item, PageType::POST)
              front_matter = normalize_object(front_matter)

              date = post_item.elements[posts_config.date || 'date'].value
              date_string = DateTime.parse(date).strftime('%Y-%m-%d')

              mapped_name = filename_resolver.execute(post_item)
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

              pages.each do |page_item|
                content = content_resolver.execute(page_item, page_config)
                front_matter = front_matter_resolver.execute(page_item, PageType::PAGE)
                front_matter = normalize_object(front_matter)

                mapped_name = filename_resolver.execute(page_item)
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
end
