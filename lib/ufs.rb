require File.join(File.expand_path(File.dirname(__FILE__)), 'metaclass') unless defined?(Object.metaclass)
require File.join(File.expand_path(File.dirname(__FILE__)), 'errors') unless defined?(UFS_Errors)
require File.join(File.expand_path(File.dirname(__FILE__)), 'string_ext') unless String.methods.include? 'constantize'

class UFS
  include UFS_Errors
  attr_accessor :path
  
  # For UFS.new only: returns an instance of the default_adapter or self if no default_adapter has been specified
  def self.new(*args, &block)
    if self == UFS
      klass = UFS.default_adapter ? UFS.default_adapter : self
      obj = klass.send(:allocate)
      obj.send(:initialize, *args, &block)
      return obj
    else
      super
    end
  end
  
  # Set or get the default filesystem adapter...  If you don't set the default 
  # adapter then the correct adapter cannnot be automatically determined.
  #
  # Example:
  #   UFS.default_adapter UFS::FS
  #   # UFS.touch is now the same thing as: UFS::FS::File.touch
  #   UFS.default_adapter   # => UFS::FS
  def self.default_adapter(type = :noting_to_set)
    @default_adapter ||= nil
    type == :noting_to_set ? @default_adapter : @default_adapter=type
  end
  
  # This is a convience method to set the default_adapter.  See default_adapter
  def self.default_adapter=(type)
    self.default_adapter type
  end
  
  # This allows a Adapter object to register methods to the default_adapter through its inheritence of UFS. 
  # The purpose for this is to be able to guess what adapter class is needed.  Registering :touch is what 
  # allows UFS::FS to be able to figure out that a method call to :touch means that you must want a UFS::FS::File.
  #
  # If the method is already registered then the registry is removed, this is a protection so that, for example, 
  # both UFS::FS::Dir & UFS::FS::File cannot register the :<< method which does different things.
  #
  # Example:
  #   # code example from lib/adapters/fs/file.rb
  #   ['touch', 'create!', "concat!", "concat", "<<", "size"].each do |meth|
  #     UFS::FS.register_downline_public_methods(meth, UFS::FS::File)
  #   end
  def self.register_downline_public_methods(meth, obj)
    if (@downline_methods ||= {}).has_key? meth
      # need to delete metod cause it must exist in multiple downlines if its already been defined
      self.metaclass.class_eval do
        undef meth
      end
    else 
      unless self.public_methods.include? meth.to_s # Don't overwrite existing methods
        self.add_class_method meth do |*args, &block|
          obj.send(meth, *args, &block)
        end
        @downline_methods
      end
    end
  end
  
  # If the public method is not found in UFS, UFS will attempt to pass the request to the default_adapter.
  #
  # Example:
  #   UFS.default_adapter = UFS::FS
  #   UFS.touch('/tmp/deleteme.txt)  # Will attempt to find a UFS::FS class method, which will return a UFS::FS::File object
  def self.method_missing(sym, *args, &block)
    if default_adapter && self == UFS
      default_adapter.send(sym, *args, &block)
    else
      super
    end
  end

  # Returns the path minus the location of the File or Dir.
  #
  # Examples:
  #   UFS::FS::File.new('/tmp/deleteme.txt').name  #=> "deleteme.txt"
  #   UFS::FS::Dir.new('/tmp/deleteme').name  #=> "deleteme"
  #   UFS::S3::S3Object.new('/tmp/deleteme.txt).name  #=> "deleteme.txt"
  def name
    path.split(::File::Separator).last
  end

  # This stores an instance of the proxy object for any methods that are proxied to the
  # proxy object.  This saves on instantizing but more importantly, saves the state of
  # the proxy object...  If object or force is set to true or :force then the proxy object
  # is assigned regardless of the current state of the proxy object.
  #
  # Important usage notes:
  #   The proxy method accepts either an object or a block, if both are assigned only the block us run.
  #
  # Examples: 
  #   proxy(::File.new('/tmp/deleteme'))  in place of  ::File.new('/tmp/deleteme')
  #
  #   proxy :force do
  #     s3 = ::AWS::S3::S3Object.new
  #     s3.key = key
  #     s3.bucket = bucket
  #     s3
  #   end
  def proxy(obj=nil, force=false, &block)
    # The following compairisons are to circumvent issues arising when the object proxied is a AWS::S3::S3Object
    #   AWS::S3::S3Objects cannot be compaired with == because it looks compairs ':path'... we are looking for true or :force exclusively
    if force.is_a?(TrueClass) || obj.is_a?(TrueClass) || :force == force || :force == obj
      @proxy_object = block.nil? ? obj : block.call
    else
      @proxy_object ||= block.nil? ? obj : block.call
    end
  end
  
  # Returns a string representation of a path from a string or array of strings.
  # Does not automatically prepend a separator unless a hash is provided with a :prefix key.
  # 
  # Example:
  #   f=UFS.new
  #   f.as_path 'path/to/some', 'world.txt'                               #=> "path/to/some/world.txt"
  #   f.as_path 'path/to', 'some', 'world.txt'                            #=> "path/to/some/world.txt"
  #   f.as_path '/path/', '/to/some//', '/', '/world.txt'                 #=> "/path/to/some/world.txt"
  #   f.as_path 'path/to/some/world.txt', {:prefix => ::File::Separator}  #=> "/path/to/some/world.txt"
  #   f.as_path 'path/to/some\world.txt', {:prefix => ::File::Separator}  #=> "/path/to/some/world.txt"
  def as_path(*args)
    # Strip any hashes out as options
    options = {}
    args.delete_if {|e| (options.merge!(e); true) if e.is_a?(Hash) }
    # Assume prefix if a file separator is given as a prefix of the first argument
    options[:prefix] ||= ::File::Separator if /^[\/|\\]/ === args.first
    # Cleanup file separator to ensure it is according to the current O.S.
    options[:prefix] = ::File::Separator if /[\/|\\]/ === options[:prefix]
    # split by arguments & file separators then combine by file separators
    options[:prefix].to_s + args.join(::File::Separator).split(/[\/|\\]/).collect {|s| s unless s.empty?}.compact.join(::File::Separator)
  end
private
  # The following allows an easy way to expand this objects Class methods without overwriting them.
  # This is useful for building proxying objects.  This method also works on anything that inherits from this object.
  #
  # Example:
  #   # The following creates a class method ie:  UFS::FS::File.join 'one', 'two', 'three'
  #   UFS::FS::File.add_class_method :join do |*args|
  #     ::File.join *args
  #   end
  def self.add_class_method(meth, &block)
    self.metaclass.send(:define_method, meth, &block) unless self.public_methods.include?(meth)
  end

  # The following allows an easy way to expand this objects Instance methods without overwriting them.
  # This is useful for building proxying objects.
  #
  # Example:
  #   # The following creates an instance method ie:  UFS::FS::File.new('/tmp/deleteme.txt').exists?
  #   UFS::FS::File.add_instance_method :exists? do |*args|
  #     ::File.exists? *args
  #   end
  def self.add_instance_method(meth, &block)
    self.class_eval do
      define_method meth, &block
    end unless self.instance_methods.include?(meth)
  end
end

# # Make the :new method optional...  appends the Kernel object.
# # This is fun but it only allows (UFS 'something') to become (UFS.new 'something')
# # I need something
# module Kernel
#   def UFS(*params)
#     ::UFS.new *params
#   end
# end
# 

# Require all adapters  requireing any: ./lib/adapters/#{adapter_name}/#{adapter_name}.rb
Dir.glob(File.expand_path(File.dirname(__FILE__))+'/adapters/*.rb').each do |adapter_file|
  begin # This allows silent failure of adapters that don't have the required gems... for instance not having the aws/s3 gem.
    require adapter_file
  rescue LoadError
  end
end
