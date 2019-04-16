class FrontMatterResolver
  def initialize(global_config, type_config, content_item)
    @global_config = global_config
    @type_config = type_config
    @content_item = content_item
  end

  def item
    {
      system: @content_item.system,
      elements: @content_item.elements,
    }
  end

  def title
    @content_item.elements[@type_config&.title || 'title']&.value
  end
end

class PageFrontMatterResolver < FrontMatterResolver
  def resolve
    {
      item: item,
      title: title,
      layout: layout
    }
  end

  def layout
    @type_config&.layout || @global_config.default_layout
  end
end

class PostFrontMatterResolver < FrontMatterResolver
  def resolve
    {
      item: item,
      title: title,
      layout: layout,
      date: date,
      categories: categories,
      tags: tags
    }
  end

  def layout
    @type_config&.layout
  end

  def date
    element = @content_item.elements[@type_config.date || 'date']
    return unless element.value

    Time.parse(element.value)
  end

  def categories
    @content_item.elements[@type_config.categories || 'categories']&.value&.map(&:codename)
  end

  def tags
    @content_item.elements[@type_config.tags || 'tags']&.value&.map(&:codename)
  end
end

module Jekyll
  module Kentico
    module Resolvers
      class ContentFrontMatterResolver
        # @return [ContentFrontMatterResolver]
        def self.resolve(config, content_item, page_type)
          registered_resolver = config.content_front_matter_resolver
          default_resolver = Jekyll::Kentico::Resolvers::ContentFrontMatterResolver.to_s

          front_matter = Module.const_get(default_resolver).new(config).resolve_internal(content_item, page_type)

          if registered_resolver
            resolver = Module.const_get(registered_resolver).new
            front_matter.merge! resolver.resolve(content_item, page_type)
          end

          front_matter
        end

        def initialize(config)
          @config = config
        end

        def resolve_internal(content_item, page_type)
          @content_item = content_item
          @page_type = page_type

          resolver_factory
            .new(@config, type_config, content_item)
            .resolve
        end

      private
        def resolver_factory
          return PostFrontMatterResolver if is_post
          PageFrontMatterResolver if is_page
        end

        def is_page
          @page_type == Constants::PageType::PAGE
        end

        def is_post
          @page_type == Constants::PageType::POST
        end

        def type_config
          return @config.posts if is_post
          @config.pages[@content_item.system.type] if is_page
        end
      end
    end
  end
end
