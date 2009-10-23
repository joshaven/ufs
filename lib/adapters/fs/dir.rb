class FSDS::FS::Dir < FSDS::FS
  # Retuns a FSDS::FS::Dir (Directory Object).  The path, permissions, ownership & group can be 
  # specified as attributes. The filesystem is not touched by this method.  The methods that 
  # make changes to the filesystem are generally ending with an exclamation point (!) and the 
  # methods that read from the filesystem are generally ending with a question mark (?).
  #
  # See also :mkdir
  #
  # Examples:
  #   FSDS::FS::Dir.new '/tmp/test'
  #   FSDS::FS::Dir.new '/tmp/test', 755
  #   FSDS::FS::Dir.new '/tmp/test', 755, 'joshaven'
  #   FSDS::FS::Dir.new '/tmp/test', 755, 'joshaven', 'staff'
  #   FSDS::FS::Dir.new '/tmp/test', nil, 'joshaven'     # The attributes are ordered, however they are ignored if nil.
  def initialize(*args)
    super *args
    self.type = FSDS::FS::Dir if type.nil?
  end
  
  # Create a file or directory on the filesystem if it doesn't already exist and set permissions, owner,
  # & group if specified. See FSDS::new for full param options.  They type paramter is required and must be 
  # one of: [:file, :dir].  Returns an FSDS instance.  See also the shortcut methods: :mkdir & :touch
  #
  #
  # Examples:
  #   p=FSDS.new  '/tmp/deleteme'         # This assumes that you have set: FSDS::default_type = FSDS::FS
  #   p.create! :file                     # Returns an instance of: FSDS::FS::File
  #
  #   # The same can be done in one line: # Also assumes that you've set: FSDS::default_type = FSDS::FS
  #   FSDS.create! :file, '/tmp/deleteme'
  #
  #   # If you need root access then send it a sudo:
  #   FSDS.create! :file, '/etc/deleteme', {:sudo => 'superSecretPassword'}
  def create!(pth=path, options={})
    options, pth = pth, options if Hash === pth   # Swap arguments if arguments are backwards
    pth = path if Hash === pth
    
    return false unless String === pth            # validate arg
    path = pth                                    # ensure the path is set
    
    cmd_prefix = options.has_key?(:sudo) ? "echo #{options[:sudo]}| sudo -S " : ''
    
    begin
      raise("Could not make dir: #{path}") unless system_to_boolean("#{cmd_prefix} mkdir #{options[:arguments]} #{path}")
      # TODO: I think this needs to revert to the above method, need to test making a dir that requires sudo
      # ::Dir::mkdir(path)
    rescue
      raise FSDS::IOError
    end unless ::File.directory? path
    
    # sudo_options = options.has_key?(:sudo) ? {:sudo => options[:sudo]} : {}
    owner! sudo_options
    group! sudo_options
    permissions! sudo_options
    
    return self
  end
  alias_method :mkdir, :create!

  
end