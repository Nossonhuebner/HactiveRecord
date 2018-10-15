class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      define_method("#{name}") { instance_variable_get("@#{name}") }
      define_method("#{name}=") { |val| instance_variable_set("@#{name}", val) }
    end
  end

  def self.my_attr_reader(*names)
    names.each do |name|
      define_method("#{name}") { instance_variable_get("@#{name}") }
    end
  end
end
