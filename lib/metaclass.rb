# This allows you to reference the class of an object as an instantiated object.  
# I am using this to be able to call object.metaclass.define_method :name, &block to dynamically define class methods
#
# Thankyou JOHN HUME: http://practicalruby.blogspot.com/2007/02/ruby-metaprogramming-introduction.html
# See also: http://www.klankboomklang.com/2007/10/05/the-metaclass/

class ::Object 
  def metaclass
    class << self
      self
    end
  end
end