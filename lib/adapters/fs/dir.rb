require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'fs') unless defined?(FSDS::FS)

class FSDS::FS::Dir < FSDS::FS
  # Retuns a FSDS::FS::Dir (Directory Object).  The path, permissions, ownership & group can be 
  # specified as attributes. The filesystem is not touched by this method.  The methods that 
  # make changes to the filesystem are generally ending with an exclamation point (!) and the 
  # methods that read from the filesystem are generally ending with a question mark (?).
  #
  # See also :mkdir
  #
  # Examples:
  #   FSDS::FS::Dir.new '/tmp/deleteme/'                      # the '/' at the end of the path is optional
  #   FSDS::FS::Dir.new '/tmp/deleteme/', 755
  #   FSDS::FS::Dir.new '/tmp/deleteme/', 755, 'joshaven'
  #   FSDS::FS::Dir.new '/tmp/deleteme/', 755, 'joshaven', 'staff'
  #   FSDS::FS::Dir.new '/tmp/deleteme/', nil, 'joshaven'     # The attributes are ordered, however they are ignored if nil.

  
  # Create a file or directory on the filesystem if it doesn't already exist and set permissions, owner,
  # & group if specified. See FSDS::new for full param options.  Returns an FSDS instance.  See also the 
  # shortcut methods: :mkdir & :touch
  #
  # Examples:
  #   p=FSDS.new  '/tmp/deleteme'         # This assumes that you have set: FSDS.default_adapter = FSDS::FS
  #   p.create! :file                     # Returns an instance of: FSDS::FS::File
  #
  #   # The same can be done in one line: # Also assumes that you've set: FSDS.default_adapter = FSDS::FS
  #   FSDS.create! :file, '/tmp/deleteme'
  #
  #   # If you need root access then send it a sudo:
  #   FSDS.create! :file, '/etc/deleteme', {:sudo => 'superSecretPassword'}
  def create!(pth=path, options={})
    options, pth = pth, options if pth.is_a? Hash   # Swap arguments if arguments are backwards
    pth = path if pth.is_a? Hash
    
    return false unless pth.is_a? String            # validate arg
    path = pth                                    # ensure the path is set
    
    cmd_prefix = options.has_key?(:sudo) ? "echo #{options[:sudo]}| sudo -S " : ''
    
    unless exists? # attempt to make directory unless it already exists.
      begin
        raise FSDS::WriteError unless system_to_boolean("#{cmd_prefix} mkdir #{options[:arguments]} #{path}")
      rescue
        raise FSDS::WriteError
      end 
    end
    
    sudo_options = options.has_key?(:sudo) ? {:sudo => options[:sudo]} : {}
    owner! sudo_options
    group! sudo_options
    permissions! sudo_options
    
    return self
  end
  alias_method :mkdir, :create!
  
  # Shortcut method to mkdir while specifying the argument '-p'.  This creates a directory and all needed
  # directories inbetween.
  #
  # Example:
  #   FSDS::Dir.mkdir! '/tmp/new_dir/my_dir'   #=> true    # this makes the new_dir & the my_dir
  def mkdir!(pth=path, options={})
    create! pth, options.merge({:arguments=>'-p'})
    # File.makedirs path  # this would be great except that it doesn't support sudo
  end
  
  # Returns true or false.
  #
  # Examples:
  #   FSDS.exists?("/tmp")           #=> true
  def exists?
    ::File.directory? self.path
  end
  
  # Returns and array of path strings contained withing the current directory.  There is no distinction between File & Dir.
  # This could easily be modified to return File & Dir objects, which would make the data distinct.
  #
  # Example:
  #   d = FSDS::FS::Dir '/tmp'
  #   d.to_a                      #=> ["/tmp/some_file.txt", "/tmp/some_dir"]
  def to_a
    ::Dir.glob(path + '/*').collect {|pth| FSDS::FS::File.new(pth)}
    # Uncomment the following to return File & Dir objects instead of Strings.
    # ::Dir.glob(path + '/*').collect {|pth| FSDS::FS.new pth}
  end
  

  # Move files or directories to directory using :<< method
  def <<(pth)
    # FSDS::FS.new(pth).move path
    pth.move(path)

    self.to_a
  end
end

# Proxy instance methods as class methods
[ 'create!', 'mkdir!', 'mkdir', 'to_a', 'exists?', 'move', 'group', 'group!', 'group?', 'owner', 'owner!', 'owner?', 'destroy!', 'permissions', 'permissions!', 'permissions?'].each do |meth|
  FSDS::FS::Dir.add_class_method meth do |*args|
    self.new(*args).send(meth)
  end
end

# Register class methods with FSDS::FS
['mkdir', 'mkdir!', 'to_a'].each do |meth|
  FSDS::FS.register_downline_public_methods(meth, FSDS::FS::Dir)
end

# The following will make a proxy method to the ::File class if the file class has the 
# proper method.  The various if statements are for alternate formats of the paramaters.
# If the method is not referenced in one of the formatting variables then the variable 
# will not be assigned.  If a ::File method is extended or modified then this feature is
# not affected unless the modification changes the order of the variables passed to the 
# method.  Also, ::File can be extended through including ftools without any changes to 
# the method proxies as long as that module is included prior to the instantation of the 
# FSDS::FS::File object.

# proxy ::Dir class methods 
::Dir.methods.each do |meth|
  case meth
  # Class proxy: () "no arguments" to ::Dir class method
  when *["pwd", "getwd"]
    # As class methods:
    FSDS::FS::Dir.add_class_method meth do
      ::Dir.send meth
    end
  # Class & Instance proxy ([path],[&block]) "optional path & optional block" to ::Dir
  when *["chdir"]
    # As class methods:
    FSDS::FS::Dir.add_class_method meth do |*args, &block|
      args.empty? ? ::Dir.send(meth, &block) : ::Dir.send(meth, *args, &block)
    end
    
    # As instance methods:
    FSDS::FS::Dir.add_instance_method meth do |*args, &block|
      args.empty? ? ::Dir.send(meth, &block) : ::Dir.send(meth, *args, &block)
    end
  # Class & Instance proxy: (path, [args], [&block]) "requires path, may or may not have other arguments" to ::dir
  when *["chroot","delete","rmdir","unlink","entries","foreach","glob","mkdir","open"]
    # As class methods:
    FSDS::FS::Dir.add_class_method meth do |*args, &block|
      ::Dir.send meth, *args, &block
    end
    # As instance methods:
    FSDS::FS::Dir.add_instance_method meth do |*args, &block|
      ::Dir.send *([meth, path, args].flatten.compact), &block
    end
  end
end

# proxy ::Dir instance methods
::Dir.instance_methods.each do |meth|
  case meth
  when *["close", "each", "path", "pos", "tell", "read", "rewind", "seek"]
    FSDS::FS::Dir.add_instance_method meth do |*args, &block|
      proxy(::Dir.new(path)).send meth, *args, &block
    end
  end
end