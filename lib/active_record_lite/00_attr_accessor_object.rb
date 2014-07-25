class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      define_method(name) { instance_variable_get("@#{name}") }
      define_method("#{name}=".to_sym) do |new_name|
         instance_variable_set("@#{name}", new_name)
      end
    end
  end
end
