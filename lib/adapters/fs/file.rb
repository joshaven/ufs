class FSDS::FS::File < FSDS::FS
  def initialize(*args)
    super *args
    self.type = FSDS::FS::File if type.nil?
  end

  # Return or set the type of the FSDS.  The answer will be one of: the adapter types, or nil
  # def type(klass = nil)
  #   if klass.nil?
  #     @type = ::File.file?(path || '') ? File : (::File.directory?(path || '') ? Dir : nil)
  #   elsif Class === klass.class
  #     @type = klass
  #   else
  #     nil
  #   end
  # end
  
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
    #####
    # Need to write this lines support code:
    #   pth,options = sort_path_and_options(pth, options)
    #####
    # from:
    options, pth = pth, options if Hash === pth   # Swap arguments if arguments are backwards
    pth = path if Hash === pth
    return false unless String === pth            # validate arg
    path = pth                                    # ensure the path is set
    #####
    
    cmd_prefix = options.has_key?(:sudo) ? "echo #{options[:sudo]}| sudo -S " : ''
    my_type = self.type  # minimize access to File.file? & File.directory?
    
    # # Depreciate system call to touch in favor of writing nothing to the file through :concat!
    # raise("Could not touch file: #{path}") unless system_to_boolean("#{cmd_prefix} touch #{options[:arguments]} #{path}")
    self.concat! ''
    
    # sudo_options = options.has_key?(:sudo) ? {:sudo => options[:sudo]} : {}
    owner! sudo_options
    group! sudo_options
    permissions! sudo_options
    
    return self
  end
  alias_method :touch, :create!
  
  # Returns true or false.  Shortcut method to: FSDS.new('/tmp').type != nil
  #
  # Examples:
  #   FSDS.exists?("/tmp")           #=> true
  def exists?
    ::File.file? path
  end
  
  
  # Removes FSDS from filesystem, returning true if successful or false if unsuccessful.
  #
  # Options:
  # * options may contain a hash with a sudo key containing a password: p.destroy!({:sudo => 'superSecret'})
  #
  # Example:
  # p = FSDS.touch('/tmp/deleteme')
  # p.destroy!                          # => true
  # p.destroy!                          # => false    # its already gone, but the FSDS object remains.
  # p.destroy! :sudo => 'superSecret'   # => false    # This does delete as super user, but its still not there
  # FSDS.destroy!('/tmp/not_here_123')  # => false    # This assumes that you have set FSDS::default_type
  def destroy!(options={})
    begin
      if options.has_key? :sudo
        system_to_boolean "echo #{options[:sudo]}| sudo -S rm #{path}"
      else
        system_to_boolean "rm #{path}"
      end
    rescue
      false
    end
  end
  
  # Appends to a file or raises FSDS::IOError.  This method does not do anything with new line characters.  If you
  # want to write a line of text see the :writeln method.  This method will railse FSDS::IOError if fild doesn't exist
  # call :concat! to create the file by writing to it.
  #
  # Example:
  #   f = FSDS::FS.touch '/tmp/deleteme'
  #   f << 'Hello'
  #   f.concat 'World'
  #   f.read                    #=> "HelloWorld"
  def concat(data)
    raise FSDS::IOError unless exists?
    concat! data
  end
  def concat!(data)
    begin
      ::File.open(path, 'a') { |f| f.print data }
      self
    rescue
      raise FSDS::IOError
    end
  end
  alias_method :<<, :concat
  
  # Writes a string with an appended newline to to a file.    
  #
  # Example:
  #   f = FSDS.new 'path/to/file'
  #   f.read   #=> "Line: 0\nLine: 1\n"
  #
  # FIXME:  should be sure prior char is a newline or prepend a newline & end with a newline
  def writeln(data)
    concat "#{data.chomp}\n"
  end

  # Returns the entire file as a string.
  #
  # Example:
  #   f = FSDS.new 'path/to/file'
  #   f.read   #=> "Line: 0\nLine: 1\n"
  def read
    ::File.read(path) # documented in IO class
  end

  # Returns a line as a String or a range of lines as an Array.  Given a 10 line file, the first line would be 0 and 
  # the last line would be 9. Represented as a range this would be: file.readln(0..9)
  # 
  # Examples:
  #   f = FSDS.new 'path/to/file'
  #   f.readln 0   #=> "Line: 0"
  #   f.readln(0..2)   #=> ["Line: 0", "Line: 1", "Line: 2"]
  def readln(line)
    if Fixnum === line
      str = ::File.readlines(path)[line]
      String === str ? str.chomp : str
    elsif Range === line
      ::File.readlines(path)[line.first, line.last+1].collect {|str| str.chomp if String === str}
    end
  end
end

# # This breaks out of the FSDS wrapper and allows access to the standard objects: File, Dir
# def method_missing(mth, *args)
#   # this assumes that a path is the standard input... this is not very protected... need to check Dile & Dir API's
#   args = [path] if args.empty?
#   
#   my_type = self.type
#   if my_type == File
#     ::File.send(mth, *args) if File.methods.include? mth.to_s
#   elsif my_type == Dir
#     ::Dir.send(mth, *args) if Dir.methods.include? mth.to_s
#   end
#   
# end