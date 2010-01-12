String.class_eval do
  def constantize
    const = Kernel
    self.split('::').each do |const_str|
      const = const.const_get const_str
    end
    return const
  end
end unless String.instance_methods.include?(:constantize)
