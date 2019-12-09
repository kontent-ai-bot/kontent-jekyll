class TestDataResolver
  def resolve(item)
    if item.system.codename == 'resolved_data'
      'Content from resolved data'
    end
  end
end