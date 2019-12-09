class TestContentResolver
  def resolve(item)
    type = item.system.type

    case type
    when 'resolved_pages' then item.elements.resolved_content ? "#{item.elements.resolved_content.value}" : nil
    else nil
    end
  end
end
