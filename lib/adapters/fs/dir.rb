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
  
  # Returns true or false.  Shortcut method to: FSDS.new('/tmp').type != nil
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
    ::Dir.glob(path + '/*')
    # Uncomment the following to return File & Dir objects instead of Strings.
    # ::Dir.glob(path + '/*').collect {|pth| FSDS::FS.new pth}
  end
  

  # Move files or directories to directory using :<< method
  def <<(pth)
    # FSDS::FS.new(pth).move path
    pth.move(path)

    self.to_a
  end
  
  
  # Removes FSDS from filesystem, returning true if successful or false if unsuccessful.
  #
  # Options:
  # * options may contain a hash with a sudo key containing a password: p.destroy!({:sudo => 'superSecret'})
  #
  # Example:
  # p = FSDS.mkdir('/tmp/deleteme')                   # This assumes that you have set FSDS::default_type
  # p.destroy!                          # => true     # Bam! Its gone... for ever...
  # p.destroy!                          # => false    # Its already gone, but the FSDS object remains.
  # p.destroy! :sudo => 'superSecret'   # => false    # This does delete as super user, but its still not there
  # FSDS.destroy!('/tmp/deleteme/nota') # => false    # This assumes that you have set FSDS::default_type
  # def destroy!(options={})
  #   begin # The :: Dir.delete method returns 0 when the 
  #     ::Dir.delete(path) == 0 ? true : false
  #   rescue # The :: Dir.delete method raises an error if dir doesn't exist
  #     false
  #   end
  #   # begin
  #   #   if options.has_key? :sudo
  #   #     system_to_boolean "echo #{options[:sudo]}| sudo -S rm -r #{path}"
  #   #   else
  #   #     system_to_boolean "rm -r #{path}"
  #   #   end
  #   # rescue
  #   #   false
  #   # end
  # end  
end