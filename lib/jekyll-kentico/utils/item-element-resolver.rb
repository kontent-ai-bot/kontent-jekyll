class ItemElementResolver
  def initialize(item)
    @item = item
  end

  def resolve_date(element_key = nil)
    element = @item.elements[element_key || 'date']
    Date.parse element.value if element
  end

  def resolve_content(element_key = nil)
    @item.get_string(element_key || 'content')
  end

  def resolve_title(element_key = nil)
    @item.elements[element_key || 'title']&.value
  end

  def resolve_categories(element_key = nil)
    @item.elements[element_key || 'categories']&.value
  end

  def resolve_tags(element_key = nil)
    @item.elements[element_key || 'tags']&.value
  end
end