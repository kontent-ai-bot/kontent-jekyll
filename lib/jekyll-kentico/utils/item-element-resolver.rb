class ItemElementResolver
  def initialize(item)
    @item = item
  end

  def resolve_date(element_key, default_key = nil)
    element = @item.elements[element_key || default_key]
    Date.parse element.value if element
  end

  def resolve_content(element_key, default_key = nil)
    @item.get_string(element_key || default_key)
  end

private
  def allowed_name_keys
    %w[codename id]
  end
end