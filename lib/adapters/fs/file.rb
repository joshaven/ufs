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
    ##### TODO:
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
    
    sudo_options = options.has_key?(:sudo) ? {:sudo => options[:sudo]} : {}
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
  
  # Returns the file size of the file in bytes.  This method is aliased as bytes
  #
  # Example:
  #   f = FSDS::FS::File.touch '/tmp/deleteme.txt'
  #   f << "123\n"
  #   f.size        # => 4   # Three numbers and a newline character
  #   f.bytes       # => 4   # Three numbers and a newline character
  def size
    exists? ? ::File.size(path) : nil
  end
  alias_method :bytes, :size
  
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
      ::File.open(path, 'a') { |f| f.print data.to_s }
      self
    rescue
      raise FSDS::WriteError
    end
  end
  alias_method :<<, :concat

  # Return the content of a file from given start byte through the finish byte.  If finish byte is not given then the end
  # of the file is assumed.  
  #
  # Examples:
  #   file = File::FS::File.touch '/tmp/deleteme.txt'
  #   file << '0123456789abcdefghij'
  #   file.read_by_bytes(0,10)    #=> "0123456789" # Returns the 1st byte for 10 consecutive byte.
  #   file.read_by_bytes(10,10)   #=> "abcdefghij" # Returns from the 10th byte for 10 consecutive bytes.
  #   file.read_by_bytes(-10,10)  #=> "abcdefghij" # Returns, the 10th from last byte for 10 consecutive byptes.
  #   file.read_by_bytes(-10)     #=> "abcdefghij" # Returns, the 10th from last byte through the end of the file.
  #   file << "\n0123456789\n"
  #   file.read_by_bytes(-12,10)  # => "\n012345678"
  #   file.read_by_bytes(-1)      # => "\n"
  #   file.read_by_bytes(1000, 1) # => RuntimeError: start byte is beyond the size of the file
  def read_by_bytes(start, finish = nil)
    raise 'start must be an Integer' unless Integer === start
    raise 'finish must be an Integer or nil' unless Integer === finish || NilClass === finish

    f = ::File.new(path)
    size = ::File.size(path)
    finish = size if finish.nil? || finish > size
    raise 'start byte is beyond the size of the file' if start.abs > size
    f.seek(start, ((start < 0) ? IO::SEEK_END : IO::SEEK_SET) )
    f.read(finish)
  end
  
  # Writes a string with an appended newline to to a file.    
  #
  # Example:
  #   f = FSDS.new 'path/to/file'
  #   f.read   #=> "Line: 0\nLine: 1\n"
  def writeln(data)
    if size > 0
      self.concat "#{$/ unless read_by_bytes(-1) == $/}#{data.to_s.chomp}#{$/}"
    else
      self.concat "#{data.to_s.chomp}#{$/}"
    end
  end

  # Returns the entire file as a string.
  #
  # Example:
  #   f = FSDS.new 'path/to/file'
  #   f.read   #=> "Line: 0\nLine: 1\n"
  def read
    begin
      ::File.read(path) # documented in IO class
    rescue
      raise FSDS::ReadError 
    end
  end

  # Returns a line as a String or a range of lines as an Array.  Given a 10 line file, the first line would be 0 and 
  # the last line would be 9. Represented as a range this would be: file.readln(0..9)
  # 
  # Examples:
  #   f = FSDS.new 'path/to/file'
  #   f.readln 0   #=> "Line: 0"
  #   f.readln(0..2)   #=> ["Line: 0", "Line: 1", "Line: 2"]
  def readln(line)
    begin
      if Fixnum === line
        str = ::File.readlines(path)[line]
        String === str ? str.chomp : str
      elsif Range === line
        ::File.readlines(path)[line.first, line.last+1].collect {|str| str.chomp if String === str}
      end
    rescue
      raise FSDS::ReadError
    end
  end

  def method_missing(mth, *args)
    # FSDS::FS.constants.each {|const| puts const.methods.include? 'touch'}
    puts "got to Method Missing!  mth: #{mth}, args: #{args.inspect}  BLANK ARGS?: #{args.empty?}"
    begin
      # these need:  (path) or (path, *args)
      if [:atime, :basename, :blockdev?, :chardev?, :catname, :compare, :copy, :ctime, :delete, :directory?, :dirname, 
          :executable?, :executable_real?, :exist?, :exists?, :expand_path, :extname, :file?, :ftype, :grpowned?, 
          :identical?, :install, :link, :lstat, :makedirs, :move, :mtime, :new, :owned?, :pipe?, :readable?, :readable_real, 
          :readlink, :rename, :safe_unlink, :setgid?, :syscopy, :size, :socket?, :split, :stat, :sticky?, :symlink, 
          :symlink?, :truncate, :unlink, :unlink, :writable?, :writable_real?, :zero?].include?(mth)
        ::File.send(*([mth, path, *args].compact)) if ::File.methods.include?(mth.to_s)
        
      elsif [:chown, :lchmod, :utime].include?(mth) # these need: (*args, path)
        ::File.send(*([mth, [*args], path].compact.flatten)) if ::File.methods.include?(mth.to_s)
        
      # these need:  ie: (arg1, path, *arg)
      elsif [:fnmatch, :fnmatch?].include? mth
        ::File.send(mth, *([args.shift, path, *args].compact)) if ::File.methods.include?(mth.to_s)
        
      # These don't need a path
      elsif [:join, :umask].include? mth
        ::File.send( *([mth, *args].compact) )
        
      # These are instance methods and thus don't need the path but must work on a ::File.new(path) object
      # these are at the end of the conditionals so duplicates with above will not be used.
      elsif [:atime, :chmod, :chown, :ctime, :flock, :lstat, :mtime, :chmod, :path, :truncate]
        ::File.new(path).send(mth, *args)
        
      end
    rescue
      FSDS::IOError
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