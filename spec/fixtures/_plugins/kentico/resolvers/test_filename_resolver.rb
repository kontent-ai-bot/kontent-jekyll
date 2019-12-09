class TestFilenameResolver
  def resolve(item)
    item.elements.resolved_filename ? "#{item.elements.resolved_filename.value}" : nil
  end
end
