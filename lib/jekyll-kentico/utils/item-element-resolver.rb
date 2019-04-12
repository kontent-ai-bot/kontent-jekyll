class ItemElementResolver
  def initialize(item)
    @item = item
  end

  def resolve_date(element_key, default_key = nil)
    value = resolve_element(element_key, default_key)
    Date.parse value if value
  end

  def resolve_element(element_key, default_key = nil)
    element = @item.elements[element_key || default_key]
    element.value if element
  end

private
  def allowed_name_keys
    %w[codename id]
  end
end