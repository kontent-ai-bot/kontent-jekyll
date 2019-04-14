class ItemElementResolver
  def initialize(item)
    @item = item
  end

  def resolve_date(element_key)
    element = @item.elements[element_key || 'date']
    Date.parse element.value if element
  end

  def resolve_content(element_key)
    @item.get_string(element_key || 'content')
  end

  def resolve_title(element_key)
    @item.elements[element_key || 'title']&.value
  end

  def resolve_taxonomy_group(taxonomy_group)
    @item.elements.to_h.values.find { |e| e.taxonomy_group == taxonomy_group }&.value&.map(&:codename)
  end
end