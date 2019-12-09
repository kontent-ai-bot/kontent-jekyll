class TestFrontMatterResolver
  def resolve(item, page_type)
    if item.system.type == 'resolved_pages' && item.elements.extra_variable
      {
        extra_variable: item.elements.extra_variable.value,
      }
    end
  end
end
