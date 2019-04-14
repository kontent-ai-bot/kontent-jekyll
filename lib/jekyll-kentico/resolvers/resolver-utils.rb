class ResolverUtils
  def self.get_resolver(class_name)
    Module.const_get(class_name).new
  end
end
