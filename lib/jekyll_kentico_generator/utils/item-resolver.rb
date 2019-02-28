class ItemResolver
  def initialize(item)
    @item = item
  end

  def resolve_filename(name_key)
    unless allowed_name_keys.include? name_key
      if name_key
        warn "pages[#{allowed_name_keys}]: Only #{allowed_name_keys} are correct values for the name key."
      end
      return @item.system.codename
    end

    @item.system.codename
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