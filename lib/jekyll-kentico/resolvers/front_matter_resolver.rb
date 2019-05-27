class FrontMatterResolverBase
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
    element = get_element(@type_config&.title || 'title')
    element&.value
  end

  def layout
    @type_config&.layout || @global_config.default_layout
  end

  def get_element(codename)
    @content_item.elements[codename]
  end
end

class PageFrontMatterResolver < FrontMatterResolverBase
  def resolve
    {
      item: item,
      title: title,
      layout: layout
    }
  end
end

class PostFrontMatterResolver < FrontMatterResolverBase
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

  def date
    element = get_element(@type_config.date || 'date')
    element && Time.parse(element.value)
  end

  def categories
    element = get_element(@type_config.categories || 'categories')
    return unless element

    element.value.map(&:codename)
  end

  def tags
    element = get_element(@type_config.tags || 'tags')
    return unless element

    element.value.map(&:codename)
  end
end

module Jekyll
  module Kentico
    module Resolvers
      class FrontMatterResolver
        def initialize(global_config)
          @global_config = global_config
        end

        def execute(content_item, page_type)
          front_matter = resolve_internal(content_item, page_type)

          if custom_resolver
            extra_data = custom_resolver.resolve(content_item, page_type)
            front_matter.merge!(extra_data)
          end

          front_matter
        end

        private

        def custom_resolver
          return @custom_resolver if @custom_resolver

          resolver_name = @global_config.front_matter_resolver
          return unless resolver_name

          @custom_resolver =  Module.const_get(resolver_name).new
        end

        def resolve_internal(content_item, page_type)
          @content_item = content_item
          @page_type = page_type

          resolver_factory
            .new(@global_config, type_config, content_item)
            .resolve
        end

        def resolver_factory
          return PostFrontMatterResolver if post?
          PageFrontMatterResolver if page?
        end

        def type_config
          return @global_config.posts if post?
          @global_config.pages[@content_item.system.type] if page?
        end

        def page?
          @page_type == Constants::PageType::PAGE
        end

        def post?
          @page_type == Constants::PageType::POST
        end
      end
    end
  end
end
